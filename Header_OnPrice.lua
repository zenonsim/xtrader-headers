price_data = {}

function update_onprice(strategy, price, fields, refresh)
    if refresh == true then
        if price_data[price:code()] == nil then
            price_data[price:code()] = price
        end
    end
end