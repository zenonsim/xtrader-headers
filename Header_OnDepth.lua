--- Market best bid/ask infor: bid	,bs,	ask,	as, last, pre_close
bid_vol          = {}
bid_price         = {}
ask_price         = {}
ask_vol         = {}
open        = {}
pre_close   = {}
ticksize    = {}
---time and sales
last        = {}
vol         = {}

-- market depth table, store max_depth rows 
md_bid      = {}
md_bq       = {}
md_ask      = {}
md_aq       = {}
max_depth   = {}
ex = nil
-- Maybe we can define our own iep?
set_IEP = {}

function Initialize_Market_Depth(sym)
    -- local sym = depth:code()
    -- md_bid      = {}
    md_bid[sym]      = {}
    -- md_bq       = {}
    md_bq[sym]       = {}
    -- md_ask      = {}
    md_ask[sym]      = {}
    -- md_aq       = {}
    md_aq[sym]       = {}
    -- max_depth = {}
    max_depth[sym] = 20
    for i = 1,max_depth[sym] do
        if i == 1 then
            md_bid[sym][i] = 0
            md_bq[sym][i]  = 0
            md_ask[sym][i] = 0
            md_aq[sym][i]  = 0
        else
            md_bid[sym][i] = 0
            md_bq[sym][i]  = 0
            md_ask[sym][i] = 999
            md_aq[sym][i]  = 0
        end
    end

    bid_vol[sym]          = 0
    bid_price[sym]         = 0
    ask_price[sym]         = 0
    ask_vol[sym]          = 0
    open[sym]        = 0
    pre_close[sym]   = 0
    ticksize[sym]    = 0
    ---time and sales
    last[sym]        = 0
    vol[sym]         = 0
    set_IEP[sym] = {}
end



function update_market_depth(strategy, depth, level, action, fields, refresh)
    ex = depth:exchange()
    local p = 0
    local qty = 0
    local row = 0
    local ticker = depth:code()
    local sym = depth:code()
    if not (ticker == sym) then return end

    local f_bid = fields & (DATA_FIELD_BID )
    local f_bv = fields & (DATA_FIELD_BID_VOL)
    local f_ask = fields & (DATA_FIELD_ASK )
    local f_av = fields & (DATA_FIELD_ASK_VOL)
        
    -- WriteLog(strategy,"level "..tostring(level))
    local act = action == DEPTH_ACTION_NEW and " New" or (action == DEPTH_ACTION_UPDATE and " Update" or " Delete" )
    if (refresh) -- if refresh is true, please ignore the paramater level, action, fields.
    then
        -- for i = max_depth,1,-1
        -- do
        --     WriteLog(strategy, sym.."  :MD[ "..tostring(i).." ] = "..tostring(md_bq[sym][i]).." @ "..tostring(md_bid[sym][i]).. " / "..tostring(md_ask[sym][i]).." @ "..tostring(md_aq[sym][i]))
        -- end
        
        -- if f_bid ~= 0 or f_bv ~= 0 then
        --     update_level(strategy,depth,SIDE_BUY,level)
        -- end
        -- if f_ask ~= 0 or f_av ~= 0 then
        --     update_level(strategy,depth,SIDE_SELL,level)
        -- end

        if f_bid ~= 0 or f_bv ~= 0 then
            
            p,qty = get_depth(depth,SIDE_BUY, level - 1)
            
            if (p> 0 and qty > 0)
            then
                if (level == 1)
                then
                    bid_price[sym] = p
                    bid_vol[sym] = qty
                end
                md_bid[sym][level] = p
                md_bq[sym][level] = qty
            end
        end
        if f_ask ~= 0 or f_av ~= 0 then
            p,qty = get_depth(depth,SIDE_SELL, level - 1)
            if (p> 0 and qty > 0)
            then
                if (level == 1)
                then
                    ask_price[sym] = p
                    ask_vol[sym] = qty
                end
                md_ask[sym][level] = p
                md_aq[sym][level] = qty
            end
        end
        if (action == DEPTH_ACTION_END_REFRESH)
        then
            if(bid_price[sym] == 0 and bid_vol[sym] == 0) then
                -- WriteLog(strategy, sym.." : Refreshing Bid ..."..tostring(md_bid[sym][i]))    
                -- ..tostring(md_bid[sym][i])
                for i = 1 , max_depth[sym] 
                do
                    p,qty = get_depth(depth,SIDE_BUY, i - 1)
                    
                    if (p> 0 and qty > 0)
                    then
                        if ( i == 1)
                        then
                            
                            bid_price[sym] = p
                            bid_vol[sym] = qty
                        end
                        md_bid[sym][i] = p
                        md_bq[sym][i] = qty
                    end
                end    
            end
            
            if(ask_price[sym] == 0 and ask_vol[sym] == 0) then
                -- WriteLog(strategy, sym.." : Refreshing Ask ... ")    
                for i = 1 , max_depth[sym] 
                do
                    p,qty = get_depth(depth,SIDE_SELL, i - 1)
                    if (p> 0 and qty > 0)
                    then
                        if ( i == 1)
                        then
                            ask_price[sym] = p
                            ask_vol[sym] = qty
                        end
                        md_ask[sym][i] = p
                        md_aq[sym][i] = qty
                    end
                end    
            end
            WriteLog(strategy, sym..": OnDepth End Refresh : my MD ask_vol[sym] follows: ")
            for i = math.min(max_depth[sym],4),1,-1
            do
                WriteLog(strategy, sym.."  MD[ "..tostring(i).." ] = "..tostring(md_bq[sym][i]).." @ "..tostring(md_bid[sym][i]).. " / "..tostring(md_ask[sym][i]).." @ "..tostring(md_aq[sym][i]))
            end

            --- for Auction , get IEP infor
            -- if true then
            if (IsAuction(ex) and not IsSmaller(bid_price[sym], ask_price[sym])) then
                set_IEP[sym] = CalculateIEP(strategy,sym,depth)
                -- if true then
                if set_IEP[sym][1] ~= 0 then
                    strategy:logEvent(0, sym..": IEP = "..tostring(set_IEP[sym][1]).." / "..tostring(set_IEP[sym][2]).." / "..tostring(set_IEP[sym][3]).." / "..tostring(set_IEP[sym][4]).." / "..tostring(set_IEP[sym][5]).." / "..tostring(set_IEP[sym][6])) 
                end
                -- WriteLog(strategy,"set_IEP "..tostring(set_IEP)
                -- .." ex "..tostring(ex)
                -- .." first el "..tostring(set_IEP[1]))
            end
        end
    else    ---- not refresh
        if f_bid ~= 0 or f_bv ~= 0 then
            item = depth:get(SIDE_BUY, level - 1)
            if (item ~= nil)
            then
                p = item.price
                qty = item.volume

                if (action == DEPTH_ACTION_UPDATE ) then
                    if (level == 1)
                    then
                        ----this is hit best ask, only valid during trading session
                        if(p == md_ask[sym][1]) then 
                            if IsTrading(ex) then DeleteMD_A(1,sym) end
                        end
                    end
                    md_bid[sym][level] = p
                    md_bq[sym][level] = qty
                elseif (action == DEPTH_ACTION_NEW ) then
                    if (p == md_bid[sym][level] ) then
                        md_bq[sym][level] = qty
                    else 
                        InsertMD_B(p,qty,level,sym)
                    end
                elseif (action == DEPTH_ACTION_DELETE ) then
                    if(p < md_bid[sym][level]) then
                        DeleteMD_B(level,sym)
                        if (qty ~= md_bq[sym][level]) then md_bq[sym][level] = qty end
                    end
                end
            end
        end
        
        if f_ask ~= 0 or f_av ~= 0 then
            item = depth:get(SIDE_SELL, level - 1)
            if (item ~= nil)
            then
                p = item.price
                qty = item.volume

                if (action == DEPTH_ACTION_UPDATE ) then
                    if (level == 1)
                    then
                        ----this is hit best bid, only valid during trading session
                        if(p == md_bid[sym][1]) then 
                            if IsTrading(ex) then DeleteMD_B(1,sym) end
                        end
                    end
                    md_ask[sym][level] = p
                    md_aq[sym][level] = qty
                    ---MarketMD_A(p,qty,level,sym)
                elseif (action == DEPTH_ACTION_NEW ) then
                    if (p == md_ask[sym][level] ) then
                        md_aq[sym][level] = qty
                    else 
                        InsertMD_A(p,qty,level,sym)
                    end
                elseif (action == DEPTH_ACTION_DELETE ) then
                    if(p > md_ask[sym][level]) then
                        DeleteMD_A(level,sym)
                        if (qty ~= md_aq[sym][level]) then md_aq[sym][level] = qty end
                    end
                end
            end
        end
        
        ---- now need to check if best Bid/Ask changed:
        if (level == 1) then
            if (bid_price[sym] ~= md_bid[sym][1] or bid_vol[sym] ~= md_bq[sym][1] or ask_price[sym] ~= md_ask[sym][1] or ask_vol[sym] ~= md_aq[sym][1] ) 
            then
                bid_price[sym] = md_bid[sym][1] > 0 and md_bid[sym][1] or md_bid[sym][2]
                bid_vol[sym] = md_bid[sym][1] > 0 and md_bq[sym][1] or md_bq[sym][2]
                ask_price[sym] = md_ask[sym][1] > 0 and md_ask[sym][1] or md_ask[sym][2]
                ask_vol[sym] = md_ask[sym][1] > 0 and md_aq[sym][1]  or md_aq[sym][2]
                -- strategy:logEvent(0, sym..": OnDepth - "..act.." ("..tostring(level)..") ; fields =  "..tostring(f_bid).." / "..tostring(f_bv).." / "..tostring(f_ask).." / "..tostring(f_av).." , Bid/Ask Values = "..tostring(bid_price[sym]).." / "..tostring(bid_vol[sym]).."  ;  "..tostring(ask_price[sym]).." / "..tostring(ask_vol[sym])) 
            end
        end

        if (IsTrading(ex) ) then
            ---- trading business here, pricing, quotation
        
        else 
        
            --- cancel working orders, etc
        end
        --- for Auction , get IEP infor
        if (IsAuction(ex) and not IsSmaller(bid_price[sym], ask_price[sym])) then
            set_IEP[sym] = CalculateIEP(strategy,sym,depth)
            -- if true then
            if set_IEP[sym][1] ~= 0 then
                strategy:logEvent(0, sym..": IEP = "..tostring(set_IEP[sym][1]).." / "..tostring(set_IEP[sym][2]).." / "..tostring(set_IEP[sym][3]).." / "..tostring(set_IEP[sym][4]).." / "..tostring(set_IEP[sym][5]).." / "..tostring(set_IEP[sym][6])) 
            end
            -- WriteLog(strategy,"set_IEP "..tostring(set_IEP)
            --     .." ex "..tostring(ex)
            --     .." first el "..tostring(set_IEP[1]))
        end
    end
end

function update_level(strategy,depth,side,level)
    p,qty = get_depth(depth,side, level - 1)
    if side == SIDE_BUY then
        md_bid[sym][level] = p
        md_bq[sym][level] = qty
    else
        md_ask[sym][level] = p
        md_aq[sym][level] = qty
    end
    if (level == 1)
    then
        ask_price[sym] = p
        ask_vol[sym] = qty
    end
end

function WriteLog(strategy, msg)
    strategy:logEvent(0,tostring(msg))
end




function InsertMD_B(p,qty,level,sym)
    if IsSmaller(level,max_depth[sym])
    then
        for i = max_depth[sym], level+1, -1
        do
            md_bid[sym][i] = md_bid[sym][i -1]
            md_bq[sym][i] = md_bq[sym][i -1]
        end
    end
    md_bid[sym][level] = p
    md_bq[sym][level] = qty
end
function InsertMD_A(p,qty,level,sym)
    if IsSmaller(level,max_depth[sym] )
    then
        for i = max_depth[sym], level+1, -1
        do
            md_ask[sym][i] = md_ask[sym][i -1]
            md_aq[sym][i] = md_aq[sym][i -1]
        end
    end
    md_ask[sym][level] = p
    md_aq[sym][level] = qty
end

function DeleteMD_B(level,sym)
   
    if IsSmaller(level,max_depth[sym] )
    then
        for i = level,max_depth[sym] - 1
        do
            md_bid[sym][i] = md_bid[sym][i + 1]
            md_bq[sym][i] = md_bq[sym][i + 1]
        end
        md_bid[sym][max_depth[sym]] = 0.0
        md_bq[sym][max_depth[sym]] = 0

    else
        md_bid[sym][level] = 0.0
        md_bq[sym][level] = 0
    end
end

function DeleteMD_A(level,sym,stgy)
    if IsSmaller(level,max_depth[sym])
    then
        for i = level,max_depth[sym] - 1
        do
            md_ask[sym][i] = md_ask[sym][i + 1]
            md_aq[sym][i] = md_aq[sym][i + 1]
        end
        md_ask[sym][max_depth[sym]] = 999.0
        md_aq[sym][max_depth[sym]] = 0
    else
        md_ask[sym][level] = 999.0
        md_aq[sym][level] = 0    
    end
end

function CalculateIEP(strategy,sym,depth)
    
    local Bid = md_bid[sym][1]
    local BV = md_bq[sym][1]
    local Ask = md_ask[sym][1]
    local AV = md_aq[sym][1]
    
    local lastP   = last[sym] > 0 and last[sym] or open[sym]

    local iep_      = 0
    local iep_vol   = 0
    local iep_b     = 0
    local iep_a     = 0
    local iep_bv    = 0
    local iep_av    = 0
    if (ex == "XSES") then
        if Bid == Ask then
            iep_ = Bid
            iep_vol = math.min(BV,AV)
            iep_b = iep_vol == BV and md_bid[sym][2] or Bid 
            iep_a = iep_vol == AV and md_ask[sym][2] or Bid 
            iep_bv = iep_vol == BV and md_bq[sym][2] or BV - iep_vol
            iep_av = iep_vol == AV and md_aq[sym][2] or AV - iep_vol 
        else
            iep_b = Bid 
            iep_a = Ask 
            iep_bv = BV
            iep_av = AV
        end
    elseif (ex == "XKLS" or ex == "XBKK") then            
        if(Bid >= Ask) then
            
            tbl = CalculateMatching(strategy,sym,lastP,open[sym],depth)
            iep_,iep_vol,iep_b,iep_a,iep_bv,iep_av = tbl[1],tbl[2],tbl[3],tbl[4],tbl[5],tbl[6]
        
        else
            iep_b = Bid 
            iep_a = Ask 
            iep_bv = BV
            iep_av = AV        
        end
    end
    
    return {iep_,iep_vol,iep_b,iep_a,iep_bv,iep_av}
    
end            

function MyBQ(strategy,depth,price,side,sym,level)
    local item = depth:get(side,level-1)
    if item ~= nil and price == item.price then
        return item:myordersqty()
    else
        return 0
    end
end
function MyAQ(strategy,depth,price,side,sym,level)
    local item = depth:get(side,level-1)
    if item ~= nil and price == item.price then
        return item:myordersqty()
    else
        return 0
    end
end

-- function CalculateMatching()
--     -- local pseudo_md_bid      = {}
--     -- md_bq       = {}
--     -- md_ask      = {}
--     -- md_aq       = {}
--     local sum_bv= {}
--     local sum_av= {}
--     local matching = {}
--     for i = 1, max_depth[sym]
--     do
--         sum_bv[i] = 0
--         sum_av[i] = 0
--         matching[i] = 0
--     end
--     for i = 1, max_depth[sym]
--     do
--         if md_bid[sym][i] == 0 then 
--             goto bid_invalid
--         end
--         if md_ask[sym][i] == 0  or md_ask[sym][i] == 0 then
--             goto ask_invalid
--         end
--         if i>1 then
--             sum_bv[i] = sum_bv[i-1] + md_bid[sym][i]
--             sum_av[i] = sum_av[i-1] + md_ask[sym][i]
--         else
--             sum_bv[i] = md_bid[i]
--             sum_av[i] = md_ask[i]
--         end
--         ::bid_invalid::
--         ::ask_invalid::
--         matching[i] = math.min(sum_bv[i],sum_av[i])
--     end
-- end

function CalculateMatching(strategy,sym,lastP,ts,depth)
    
    local D     = {}
    local P     = {}
    local bv    = {}
    local av    = {}
    local sum_bv= {}
    local sum_av= {}
    local sumv  = {}
    local idx_b = {}
    local idx_a = {}
    local idx   = {}
    local matchQ = {}
    local balanceQ = {}
    
    local iep   = 0
    local iep_vol = 0
    local iep_b = 0
    local iep_bv= 0
    local iep_a = 0
    local iep_av= 0    

    if (md_bid[sym][1] > 0 and md_ask[sym][1] > 0 )  then
        for i = 1, max_depth[sym]
        do
            ----- note MyBQ(md_bid[sym][i]/MyAQ(md_ask[sym][i]) is my working order qty on the price level
            -- WriteLog(strategy,"i = "..tostring(i).."price = "..tostring(md_bid[sym][i]))
            table.insert(D,{md_bq[sym][i] - MyBQ(strategy,depth,md_bid[sym][i],SIDE_BUY,sym,i),md_bid[sym][i],md_ask[sym][i],md_aq[sym][i] - MyAQ(strategy,depth,md_ask[sym][i],SIDE_SELL,sym,i)})
        end
    else
        table.insert(D,{md_bq[sym][1],math.max(MoveUpPriceByMkt(ex,md_bid[sym][2],1),md_ask[sym][max_depth[sym]]),math.min(MoveDownPriceByMkt(ex,md_ask[sym][2],1),md_bid[sym][max_depth[sym]]),md_aq[sym][1]})
        for i = 2, max_depth[sym]
        do
            ----- note MyBQ(md_bid[sym][i]/MyAQ(md_ask[sym][i]) is my working order qty on the price level
            table.insert(D,{md_bq[sym][i] - MyBQ(strategy,depth,md_bid[sym][i],SIDE_BUY,sym,i),md_bid[sym][i],md_ask[sym][i],md_aq[sym][i] - MyAQ(strategy,depth,md_ask[sym][i],SIDE_SELL,sym,i)})
        end
    end
    
    if (D[1][2] < D[1][3]) then
        iep   = 0
        iep_vol = 0
        iep_b = D[1][2]
        iep_a = D[1][3]
        iep_bv = D[1][1]
        iep_av = D[1][4]
    elseif (D[1][2] == D[1][3]) then
        iep = D[1][2]
        iep_vol = math.min(D[1][1],D[1][4])
        iep_b = iep_vol == D[1][1] and D[2][2] or D[1][2]
        iep_a = iep_vol == D[1][4] and D[2][3] or D[1][3]
        iep_bv = iep_vol == D[1][1] and D[2][1] or D[1][1] - iep_vol
        iep_av = iep_vol == D[1][4] and D[2][4] or D[1][4] - iep_vol 
    
    else    ----now calculate the cross IEP infor
        local sumb = 0
        local suma = 0
        for i = 1, max_depth[sym]
        do
            key_b = string.format('%.4f', D[i][2])
            key_a = string.format('%.4f', D[i][3])
            
            bv[key_b] = D[i][1]
            av[key_a] = D[i][4]
            
            idx_b[key_b] = i
            idx_a[key_a] = i
        end

        local maxp = MoveUpPriceByMkt(ex,D[1][2],1)
        local minp = MoveDownPriceByMkt(ex,D[1][3],1)
        
        local p0 = maxp
        local key = ""
        while ( p0 > minp)
        do
            key = string.format('%.4f', p0)
            if (p0 == maxp) or (idx_b[key] ~= nil or idx_a[key] ~= nil) then
                table.insert(P,p0)
                bv[key] = bv[key] ~= nil and bv[key] or 0
                av[key] = av[key] ~= nil and av[key] or 0
                idx[key] = {idx_b[key] ~= nil and idx_b[key] or 0, idx_a[key] ~= nil and idx_a[key] or 0}
            end
            p0 = MoveDownPriceByMkt(ex,p0,1)
        end
        
        sumb = 0
        suma = 0
        if(#P > 0) then
            for i = 1,#P do
                key = string.format('%.4f', P[i])
                key_a =  string.format('%.4f', P[#P - i + 1])
                sumb = sumb + bv[key]
                suma = suma + av[key_a]
                sum_bv[key] = sumb
                sum_av[key_a] = suma
            end
            b0 = 0
            for i = #P,1,-1 do
                key = string.format('%.4f', P[i])
                matchQ[i] = math.min(sum_bv[key],sum_av[key])
                balanceQ[i] = sum_av[key] - sum_bv[key]
            end
            
            ---id = {}
            local id = maxvalue(matchQ)
            
            if #id == 1 then
                idd = id[1]

                iep = P[idd]
                iep_vol = matchQ[idd]
                ---now determine iep_bid/ask
                key = string.format('%.4f', iep)
                if balanceQ[idd] > 0 then       --- SumBQ < SumAQ
                    iep_a = iep
                    iep_av = balanceQ[idd]
                    if idx[key][1] > 0 then     ---- there's bid price on this price (key) 
                        iep_b = D[idx[key][1]+1][2]
                        iep_bv = D[idx[key][1]+1][1]
                    else
                        iep_bv,iep_b = findIEP_Bid(iep,D)
                    end
                elseif balanceQ[idd] == 0  then
                    if idx[key][1] > 0 then     ---- there's bid price on this price (key) 
                        iep_b = D[idx[key][1]+1][2]
                        iep_bv = D[idx[key][1]+1][1]
                    else
                        iep_bv,iep_b = findIEP_Bid(iep,D)
                    end
                    
                    if idx[key][2] > 0 then     ---- there's ask price on this price (key) 
                        iep_a = D[idx[key][2]+1][3]
                        iep_av = D[idx[key][2]+1][4]
                    else
                        iep_av,iep_a = findIEP_Ask(iep,D)
                    end
                else            --- sumBQ > sumAQ 
                    iep_b = iep
                    iep_bv = math.abs(balanceQ[idd])
                    
                    if idx[key][2] > 0 then     ---- there's ask price on this price (key) 
                        iep_a = D[idx[key][2]+1][3]
                        iep_av = D[idx[key][2]+1][4]
                    else
                        iep_av,iep_a = findIEP_Ask(iep,D)
                    end
                end
            else
                table.sort(id)
                for i = 1,#id
                do
                    if(balanceQ[id[i]] < 0 ) then 
                        iep = P[id[i]]
                        iep_vol = matchQ[id[i]]
                        iep_b = iep
                        iep_bv = math.abs(balanceQ[id[i]])
                        key = string.format('%.4f', iep)    
                        
                        if idx[key][2] > 0 then     ---- there's ask price on this price (key) 
                            iep_a = D[idx[key][2]+1][3]
                            iep_av = D[idx[key][2]+1][4]
                        else
                            iep_av,iep_a = findIEP_Ask(iep,D)
                        end
                        return {iep,iep_vol,iep_b,iep_a,iep_bv,iep_av }
                        
                    elseif balanceQ[id[i]] == 0  then
                        iep = P[id[i]]
                        iep_vol = matchQ[id[i]]
                        key = string.format('%.4f', iep)    
                        if idx[key][1] > 0 then     ---- there's bid price on this price (key) 
                            iep_b = D[idx[key][1]+1][2]
                            iep_bv = D[idx[key][1]+1][1]
                        else
                            iep_bv,iep_b = findIEP_Bid(iep,D)
                        end
                        
                        if idx[key][2] > 0 then     ---- there's ask price on this price (key) 
                            iep_a = D[idx[key][2]+1][3]
                            iep_av = D[idx[key][2]+1][4]
                        else
                            iep_av,iep_a = findIEP_Ask(iep,D)
                        end

                        return {iep,iep_vol,iep_b,iep_a,iep_bv,iep_av }
                    end
                    --- all balanceQ are positive, choose the smallest P
                    iep = P[id[#id]]
                    iep_vol = matchQ[id[#id]]
                    iep_a = iep
                    iep_av = balanceQ[id[#id]]

                    key = string.format('%.4f', iep)  
                    if idx[key][1] > 0 then     ---- there's bid price on this price (key) 
                        iep_b = D[idx[key][1]+1][2]
                        iep_bv = D[idx[key][1]+1][1]
                    else
                        iep_bv,iep_b = findIEP_Bid(iep,D)
                    end
                    
                end
            end
        end
    end
    return {iep,iep_vol,iep_b,iep_a,iep_bv,iep_av }
end


function maxvalue(tbl)
    local idx = {}
    local r = {}
    for i = 1, #tbl do idx[i] = i end -- build a table of indexes
    -- sort the indexes, but use the values ask_vol[sym] the sorting criteria
    table.sort(idx, function(a, b) return tbl[a] > tbl[b] end)
    -- return the sorted indexes
    --return (table.unpack or unpack)(idx)
    maxv = tbl[idx[1]]
    table.insert(r,idx[1])
    if #idx == 1 then return r end
    for i = 2,#idx do
        if tbl[idx[i]] == maxv then table.insert(r, idx[i]) end
    end

    return r
    
end

function findIEP_Bid(iep,D)
    for i = 1,#D 
    do
        if (D[i][2] < iep) then return D[i][1],D[i][2] end
    end
    return 0,0
end     

function findIEP_Ask(iep,D)
    for i = 1,#D 
    do
        if (D[i][3] > iep) then return D[i][4],D[i][3] end
    end
    
    return 0,0
end    
     


function get_depth(depth,side, level)
    local item = depth:get(side,level)
    if item == nil then
        return 0,0
    else
        return item.price, item.volume
    end
end