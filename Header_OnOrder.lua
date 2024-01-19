require "Header"

orderTable = {}
orderID = {}
orderLevel = {}
executedQty = {}

function Initialize_Order_Table(sym)
    orderID[sym] = {}
    orderTable[sym] = {}
    orderLevel[sym] = {}

    for i = 1, 2 do
        local side
        if (i == 1) then
            side = SIDE_BUY
        else
            side = SIDE_SELL
        end

        orderTable[sym][side] = {}
        orderLevel[sym][side] = {}
    end
end

function updateOrderTable(order)
    local sym = order.code
    local side = order.side
    local status = order.order_status

    if (status == ORDER_STATUS_NEW) then
        if (contains(orderID[sym]) == nil) then
            newOrder(order)
        end
    elseif (status == ORDER_STATUS_PARTIALLY_FILLED) then
        executedQty[order.orderid] = order.exec_qty
    elseif (status == ORDER_STATUS_FILLED) then
        executedQty[order.orderid] = order.exec_qty
        print('test remove')
        removeOrder(order)
    elseif (status == ORDER_STATUS_CANCELLED) then
        if (contains(orderID[sym], order.orderid) ~= nil) then
            executedQty[order.orderid] = nil
            removeOrder(order)
        end
    elseif (status == ORDER_STATUS_REPLACED) then
        print('test')
    elseif (status == ORDER_STATUS_REJECTED) then
        error('Order rejected')
    end
     
end

function newOrder(order)
    local sym = order.code
    local side = order.side
    local orderPrice = order.order_price

    table.insert(orderID[sym], order.orderid)

    local level = contains(orderLevel[sym][side], orderPrice)

    if (level ~= nil) then
        orderTable[sym][side][level][order.orderid] = order
    else
        orderLevel[sym][side] = addLevel(orderLevel[sym][side], side, orderPrice)

        level = contains(orderLevel[sym][side], orderPrice)

        addOrder(orderTable, level, order)
    end
    executedQty[order.orderid] = 0
end

function removeOrder(order)
    local sym = order.code
    local side = order.side
    local orderPrice = order.order_price

    local level = contains(orderLevel[sym][side], orderPrice)

    if (isLastOrder(orderTable[sym][side][level])) then
        local newTable = {}

        for i, v in ipairs(orderTable[sym][side]) do 
            if (i < level) then
                newTable[i] = v
            elseif (i > level) then
                newTable[i - 1] = v
            end
        end

        orderTable[sym][side] = newTable

        removeLevel(orderLevel[sym][side], orderPrice)
    else
        orderTable[sym][side][level][order.orderid] = nil
    end
    
    orderID[sym][order.orderid] = nil
end

-- Helper functions
function addOrder(orderTable, level, order)
    local newTable = {}
    local sym = order.code
    local side = order.side

    for i, v in ipairs(orderTable[sym][side]) do
        if (i < level) then
            newTable[i] = v
        elseif (i >= level) then
            newTable[i + 1] = v
        end
    end
    newTable[level] = {}
    newTable[level][order.orderid] = order

    orderTable[sym][side] = newTable
end

function addLevel(level, side, price)
    if (isEmpty(level)) then
        return {price}
    else
        if (contains(level, price) == nil) then
            local newLevel = {}
            local index
            if (side == SIDE_BUY) then
                for i, v in ipairs(level) do
                    if (v > price) then
                        newLevel[#newLevel + 1] = v
                    else
                        index = #newLevel + 1
                        newLevel[#newLevel + 2] = v
                    end
                end
                newLevel[index] = price
            else
                for i, v in ipairs(level) do
                    if (v < price) then
                        newLevel[#newLevel + 1] = v
                    else
                        index = #newLevel + 1
                        newLevel[#newLevel + 2] = v
                    end
                end
                newLevel[index] = price
            end

            return newLevel
        else
            return level
        end
    end
end

function removeLevel(levelTable, price)
    local level = contains(levelTable, price)
    local newTable = {}

    print(level)
    if (level == #levelTable) then
        levelTable[#levelTable] = nil

        return levelTable
    else
        for i, v in ipairs(levelTable) do
            if (i < level) then
                newTable[i] = v
            elseif (i > level) then
                newTable[i - 1] = v2
            end 
        end
        return newTable
    end
end

function contains(table, value)
    local res = nil
    for k, v in pairs(table) do
        if (v == value) then
            res = k
            break
        end
    end
    return res
end

function isEmpty(table)
    local bool = true
    for _, value in pairs(table) do
        if (value ~= nil) then
            bool = false
            break
        end
    end
    return bool
end

function isLastOrder(table)
    local counter = 0
    for k, v in pairs(table) do 
        counter = counter + 1
        if (counter > 1) then
            break
        end
    end

    return (counter == 1)
end

-- Testing function
function test()
    Initialize_Order_Table('D05')

    testOrder = {
        code = 'D05',
        side = SIDE_BUY,
        order_price = 1,
        orderid = 'test',
        order_status = ORDER_STATUS_NEW
    }

    testOrder2 = {
        code = 'D05',
        side = SIDE_BUY,
        order_price = 1.01,
        orderid = 'test2',
        order_status = ORDER_STATUS_NEW
    }

    updateOrderTable(testOrder)
    updateOrderTable(testOrder2)

    testOrder2 = {
        code = 'D05',
        side = SIDE_BUY,
        order_price = 1.01,
        orderid = 'test2',
        order_status = ORDER_STATUS_FILLED
    }

    updateOrderTable(testOrder2)

    -- removeOrder(testOrder2)
end