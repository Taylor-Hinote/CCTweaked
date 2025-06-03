local version = "0.1"
local productName = "Injest Rates"

local controller = peripheral.wrap("functionalstorage:storage_controller_0")
local monitor = peripheral.find("monitor")

if not controller or not monitor then
    error("Storage controller or monitor not found")
end

monitor.setTextScale(0.5)
monitor.setBackgroundColor(colors.black)
monitor.clear()

local WIDTH, HEIGHT = monitor.getSize()
local LINES = HEIGHT
local LINES_PER_PAGE = LINES - 7 -- Reserve lines for buttons + spacing

local SORT_MODES = {
    {name="A -> Z", sort=function(a,b) return a.name < b.name end},
    {name="Z -> A", sort=function(a,b) return a.name > b.name end},
    {name="Count Asc", sort=function(a,b) return a.count < b.count end},
    {name="Count Desc", sort=function(a,b) return a.count > b.count end},
    {name="Input Asc", sort=function(a,b) return a.rate < b.rate end},
    {name="Input Desc", sort=function(a,b) return a.rate > b.rate end},
}
local sortModeIndex = 6
local currentPage = 1

local previousCounts = {}
local itemList = {}

local function shortName(raw, maxLen)
    local name = raw:match(":(.+)") or raw
    if #name > maxLen then
        return name:sub(1, maxLen - 3) .. "..."
    end
    return name
end

local function rateColor(rate)
    if rate > 0 then return colors.lime
    elseif rate < 0 then return colors.red
    else return colors.gray end
end

local startTime = os.clock()
local lastRateUpdate = startTime
local countdownDuration = 60
local countdownOver = false

-- Initial capture of counts at start, to use after countdown ends
local function captureInitialCounts()
    local raw = controller.list()
    for _, item in pairs(raw) do
        previousCounts[item.name] = item.count
        -- Also add items to itemList here to avoid missing any on first draw
        local found = false
        for _, entry in ipairs(itemList) do
            if entry.name == item.name then
                found = true
                break
            end
        end
        if not found then
            table.insert(itemList, {name = item.name, count = item.count, rate = 0})
        end
    end
end

captureInitialCounts()

local function refreshItems()
    local now = os.clock()
    local raw = controller.list()
    local currentCounts = {}
    local seen = {}

    -- Aggregate current counts
    for _, item in pairs(raw) do
        currentCounts[item.name] = (currentCounts[item.name] or 0) + item.count
    end

    -- Update counts in itemList (always)
    for _, entry in ipairs(itemList) do
        local name = entry.name
        entry.count = currentCounts[name] or 0
        seen[name] = true
    end

    -- Add new items to list
    for name, count in pairs(currentCounts) do
        if not seen[name] then
            table.insert(itemList, {
                name = name,
                count = count,
                rate = 0
            })
        end
    end

    -- Only calculate rates if countdown is over
    if countdownOver then
        -- Update rates every 60 seconds
        if now - lastRateUpdate >= countdownDuration then
            for _, entry in ipairs(itemList) do
                local name = entry.name
                local oldCount = previousCounts[name] or entry.count
                local newCount = currentCounts[name] or 0
                local delta = newCount - oldCount
                entry.rate = delta -- counts per minute
                previousCounts[name] = newCount
            end
            lastRateUpdate = now
        end
    end
end

local function drawButton(x, y, label, fgColor, bgColor)
    local len = #label + 2
    monitor.setBackgroundColor(bgColor)
    monitor.setTextColor(fgColor)
    monitor.setCursorPos(x, y)
    monitor.write(" " .. label .. " ")
    monitor.setBackgroundColor(colors.black)
    return {x1 = x, x2 = x + len - 1, y1 = y, y2 = y}
end

local function isInside(x, y, bounds)
    return x >= bounds.x1 and x <= bounds.x2 and y >= bounds.y1 and y <= bounds.y2
end

local sortButton, prevButton, nextButton

local function draw()
    monitor.clear()
    local now = os.clock()
    local elapsed = now - startTime
    local countdown = math.max(0, countdownDuration - math.floor(elapsed))
    local timeUntilRateUpdate = countdownOver and (countdownDuration - math.floor(now - lastRateUpdate)) or countdown

    if countdownOver then
        -- Line 1: Blank
        monitor.setCursorPos(1, 1)
        monitor.setBackgroundColor(colors.black)
        monitor.setTextColor(colors.black)
        monitor.write(string.rep(" ", WIDTH))

        -- Line 2: Header with "Ingest Rates" and timer
        monitor.setCursorPos(1, 2)
        monitor.setBackgroundColor(colors.black)
        monitor.setTextColor(colors.white)
        monitor.write(productName + " v" +version)

        local timerText = "Next update in: " .. timeUntilRateUpdate .. "s"
        monitor.setCursorPos(WIDTH - #timerText + 1, 2)
        monitor.write(timerText)

        -- Line 3: Blank
        monitor.setCursorPos(1, 3)
        monitor.setBackgroundColor(colors.black)
        monitor.setTextColor(colors.black)
        monitor.write(string.rep(" ", WIDTH))
    end

    if elapsed < countdownDuration then
        -- Show startup countdown screen below header
        local message = "Starting in " .. countdown .. " seconds..."
        local midX = math.floor((WIDTH - #message) / 2) + 1
        local midY = math.floor((LINES + 3) / 2)

        monitor.setCursorPos(midX, midY)
        monitor.setTextColor(colors.yellow)
        monitor.write(message)
    else
        if not countdownOver then
            -- On first frame after countdown ends, calculate initial rates
            countdownOver = true
            lastRateUpdate = now

            -- Calculate initial rates based on difference from initial snapshot
            local raw = controller.list()
            local currentCounts = {}
            for _, item in pairs(raw) do
                currentCounts[item.name] = (currentCounts[item.name] or 0) + item.count
            end
            for _, entry in ipairs(itemList) do
                local name = entry.name
                local oldCount = previousCounts[name] or entry.count
                local newCount = currentCounts[name] or 0
                local delta = newCount - oldCount
                entry.rate = delta
                previousCounts[name] = newCount
                entry.count = newCount
            end
        end

        -- Display item list with adjusted height and starting line
        table.sort(itemList, SORT_MODES[sortModeIndex].sort)

        local totalPages = math.max(1, math.ceil(#itemList / LINES_PER_PAGE))
        if currentPage > totalPages then currentPage = totalPages end

        local startIndex = (currentPage - 1) * LINES_PER_PAGE + 1
        local endIndex = math.min(startIndex + LINES_PER_PAGE - 1, #itemList)
        local nameMaxLen = 16

        for i = startIndex, endIndex do
            local item = itemList[i]
            local line = i - startIndex + 4 -- Start from line 4
            monitor.setCursorPos(1, line)
            monitor.setTextColor(rateColor(item.rate))
            local displayName = shortName(item.name, nameMaxLen)
            local rateStr = (item.rate > 0 and "+" or "") .. tostring(item.rate) .. "/min"
            monitor.write(string.format("%-"..nameMaxLen.."s %6d %8s", displayName, item.count, rateStr))
        end

        -- Adjust button line Y positions
        sortButton = drawButton(1, LINES - 2, "Sort: "..SORT_MODES[sortModeIndex].name, colors.yellow, colors.gray)

        local pageInfo = string.format("Page %d/%d", currentPage, totalPages)
        monitor.setCursorPos(2, LINES - 1)
        monitor.setTextColor(colors.white)
        monitor.write(pageInfo)

        prevButton = drawButton(WIDTH - 22, LINES - 1, "< Prev", colors.white, colors.gray)
        nextButton = drawButton(WIDTH - 10, LINES - 1, "Next >", colors.white, colors.gray)

        monitor.setCursorPos(1, LINES)
        monitor.setBackgroundColor(colors.black)
        monitor.write(string.rep(" ", WIDTH))
    end
end

local function monitorTouch()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        if sortButton and isInside(x, y, sortButton) then
            sortModeIndex = sortModeIndex % #SORT_MODES + 1
        elseif prevButton and isInside(x, y, prevButton) then
            currentPage = math.max(1, currentPage - 1)
        elseif nextButton and isInside(x, y, nextButton) then
            local maxPage = math.max(1, math.ceil(#itemList / LINES_PER_PAGE))
            currentPage = math.min(maxPage, currentPage + 1)
        end
    end
end

local function updateLoop()
    while true do
        refreshItems()
        draw()
        sleep(1)
    end
end

local function handleTerminate()
    while true do
        os.pullEvent("terminate")
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.setTextColor(colors.white)
        monitor.write("Stopped.")
        break
    end
end

parallel.waitForAny(updateLoop, monitorTouch, handleTerminate)
