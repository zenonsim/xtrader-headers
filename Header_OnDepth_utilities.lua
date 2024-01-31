--#############################################################################
--Copyright(C)2021-2022, 3x Solution Private Limited. All Rights Reserved.
--
--NOTICE:  All information contained herein is, and remains
--the property of 3x Solution Private Limited.
--The intellectual and technical concepts contained
--herein are proprietary to 3x Solution Private Limited
--and may be covered by Singapore and Foreign Patents,
--patents in process, and are protected by trade secret or copyright law.
--Dissemination of this information or reproduction of this material
--is strictly forbidden unless prior written permission is obtained
--from 3x Solution Private Limited.
--
--For more details about this license, please read LICENSE.txt. Visit us
--at https://www.3xsolution.com if you need any support or clarification.
--#############################################################################
--##Refer to the Header.lua file for the description of the function and objects.
require "Header"
-- require "Header_mydate"
-- require "Header_TradingStatus"

EPSILON = 0.000001

--Futures Contract Size: {{ContractCode,size}}
--#####################################
DT_ContractSize = {{"TU",1000}}

--#####################################
UDF_DEPTH_NEW_BID = 481
UDF_DEPTH_NEW_ASK = 482
UDF_DEPTH_UPDATE_BID = 491
UDF_DEPTH_UPDATE_ASK = 492
UDF_DEPTH_DELETE_BID = 501
UDF_DEPTH_DELETE_ASK = 502

---for order Status and Side

--#############################################################################
--User define functions
--
--    @param1 : price
--    @param2 : indicator as for buy or sell, 1 for buy, otherwise for sell
--#############################################################################


stgy_holder = nil
function import_strategy(stgy)
    stgy_holder = stgy
    -- return stgy
end

function printlog(msg)
    stgy_holder:logEvent(0,msg)
end



function TickSize(ex,p,bs)
    ticksize = 0.0
    if ex ==  "XSES" then
        if(bs == 1)		--- for move up price 
        then
            if(p < 0.2)
            then 
                ticksize = 0.001
            else
                if(p < 1.00)
                then
                    ticksize = 0.005
                else
                    ticksize = 0.01
                end
            end
        else			--- for move down price
            if(p <= 0.2)
            then 
                ticksize = 0.001
            else
                if(p <= 1.00)
                then
                    ticksize = 0.005
                else
                    ticksize = 0.01
                end
            end
        end
    end
    if ex == "XKLS"then
        if(bs == 1)		--- for move up price 
        then
            if(p < 1.00)
            then 
                ticksize = 0.005
            else
                if(p < 10.00)
                then
                    ticksize = 0.01
                else
                    if p < 100.00 then
                        ticksize = 0.02
                    else
                        ticksize = 10
                    end
                end
            end
        else			--- for move down price
            if(p <= 1.00)
            then 
                ticksize = 0.005
            else
                if(p <= 10.00)
                then
                    ticksize = 0.01
                else
                    if p <= 100.00 then
                        ticksize = 0.02
                    else
                        ticksize = 10
                    end
                end
            end
        end
    end
    if ex == "XBKK" then
        if(bs == 1)		--- for move up price 
        then
            if(p < 2.00)
            then 
                ticksize = 0.01
            else
                if(p < 5.00)
                then
                    ticksize = 0.02
                else
                    if p < 10.00 then
                        ticksize = 0.05
                    else
                        if p<25.00 then
                            ticksize = 0.1
                        else
                            if p<100.00 then
                                tick_size =0.25
                            else
                                if p<200.00 then
                                    tick_size = 0.5
                                else
                                    if p<400.0 then
                                        tick_size = 1.00
                                    else
                                        tick_size = 2.00
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else			--- for move down price
            if(p <= 2.00)
            then 
                ticksize = 0.01
            else
                if(p <= 5.00)
                then
                    ticksize = 0.02
                else
                    if p <= 10.00 then
                        ticksize = 0.05
                    else
                        if p<=25.00 then
                            ticksize = 0.1
                        else
                            if p<=100.00 then
                                tick_size =0.25
                            else
                                if p<=200.00 then
                                    tick_size = 0.5
                                else
                                    if p<=400.0 then
                                        tick_size = 1.00
                                    else
                                        tick_size = 2.00
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end   
    end
    return ticksize

end

function FormatPriceTS(BS,p,ts)

	if not IsGreater(ts,0) then return p end

	if (BS == "B")
	then 
		return  math.floor((p + EPSINON) / ts) * ts
	else
		return  math.ceil((p - EPSINON) / ts) * ts
	end

end

function FormatPrice(p,BS)
	
	if (BS == "B")
	then 
		ts = TickSize(p,0)
		return  math.floor((p + EPSINON) / ts) * ts
	else
		ts = TickSize(p,1)
		return  math.ceil((p - EPSINON) / ts) * ts
	end

end

function MoveDownPrice(p,ticks)

    if (ticks > 0)
    then
        while(ticks > 0)
        do 
           p = p - TickSize(p,0)
           ticks = ticks - 1
        end
    end

    return p

end
function MoveDownPrice(p,ticks)

    if (ticks > 0)
    then
        while(ticks > 0)
        do 
           p = p - TickSize(p,0)
           ticks = ticks - 1
        end
    end

    return p

end

function MoveDownPriceByMkt(ex,p,ticks)
    if (ticks > 0)
    then
        while(ticks > 0)
        do 
           p = p - TickSize(ex,p,1)
           ticks = ticks - 1
        end
    end

    return p

end
function MoveUpPriceByMkt(ex,p,ticks)
    if (ticks > 0)
    then
        while(ticks > 0)
        do 
            p = p + TickSize(ex,p,1)
            ticks = ticks - 1
        end
    end

    return p
end

function HowManyTicks(p1, p2)
    Ticks = 0
    p0 = p1
    if(IsEqual(p1,p2))
    then
        return 0
    else
        if (IsSmaller(p1, p2))
        then
            while (IsSmaller(p0, p2))
            do
                p0 = p0 + TickSize(p0, 1)
                Ticks = Ticks +1
            end
        else
            while (IsGreater(p0, p2))
            do
                p0 = p0 - TickSize(p0, 0)
                Ticks = Ticks - 1
            end
        end
    end
    return Ticks
end

function IsEqual(v1, v2) 
    if (math.abs(v1 - v2) < EPSINON)
    then
        return true
    else
        return false
    end
end


function NotEqual(v1, v2) 
    if (math.abs(v1 - v2) > EPSINON)
    then
        return true
    else
        return false
    end
end


function IsSmaller(v1, v2) 
    if (math.abs(v1 - v2) < EPSINON)
    then
        return false
    else
        if(v1 < v2)
        then 
            return true
        else
            return false
        end
    end
end

function IsGreater(v1, v2) 
    if (math.abs(v1 - v2) < EPSINON)
    then
        return false
    else
        if(v1 > v2)
        then 
            return true
        else
            return false
        end
    end
end

function getFTMonthCode(con_type,m,seq)
	if (con_type == "M")
	then
		return FTMCode(seq1[m + seq - 1])
	elseif (con_type == "Q")
	then
		if IsEqual(seq,1)
		then
			return FTMCode(seq1[m])
		elseif IsEqual(seq,2)
		then
			return FTMCode(seq2[m])
		elseif IsEqual(seq,3)
		then
			return FTMCode(seq3[m])
		end
	end
end

function getYearCode(y,m,seq)
	if IsEqual(seq, 3)
	then
		if IsSmaller(m,11)
		then
			return y
		else
			return y + 1
		end
	elseif IsEqual(m,2)
	then
		if IsSmaller(m,12)
		then
			return y
		else
			return y + 1
		end	
	else
		return y
	end
end

function FTMCode(m)
	if ( m > 0 and IsSmaller(m,13))
	then
		return M_Code[m]
	else
		return ""
	end

end

function FormatQty(qty,min_qty)

	if IsGreater(min_qty, 0) 
	then 
		return math.floor(qty / min_qty + 0.5) * min_qty
	else
		return qty
	end
	
end

-------spread in in abslute number
function HowManyTicksTS(p1, p2,ts)
	if (ts > EPSILON) 
	then
		return math.floor((math.abs(p1 - p2) + EPSILON) / ts)
	else
		return 0
	end
end

function GetOrderLocks(status)
---------------
--  ORDER_STATUS_PENDINGNEW = 65
--  ORDER_STATUS_NEW = 48
--  ORDER_STATUS_FILLED = 50
--  ORDER_STATUS_PARTIALLY_FILLED = 49
--  ORDER_STATUS_PENDINGREPLACE = 69
--  ORDER_STATUS_PENDINGCANCEL = 54
--  ORDER_STATUS_REJECTED = 56
--  ORDER_STATUS_CANCELLED = 52
--  ORDER_STATUS_REPLACED = 53
---------
    if (status == ORDER_STATUS_PENDINGNEW or
        status == ORDER_STATUS_PENDINGREPLACE or
        status == ORDER_STATUS_PENDINGCANCEL )
    then
        return true
    else
        return false
    end
end
