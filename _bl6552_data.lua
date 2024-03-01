log.info("shell -- file -- _bl6552_data -- start")

--------------------------------------------
--------------------------------------------

local _ZXTO_IN_NUM = 40  --输入缺相系数
local _ZXTO_OUT_NUM = 4  --输出缺相系数
----------------------------------通道1
-- 电流
local BL6552_Elect_IA_RMS_Chx = {0,0,0,0}
local BL6552_Elect_IB_RMS_Chx = {0,0,0,0}
local BL6552_Elect_IC_RMS_Chx = {0,0,0,0}
-- 电压
local BL6552_Elect_VA_RMS_Chx = {0,0,0,0}
local BL6552_Elect_VB_RMS_Chx = {0,0,0,0}
local BL6552_Elect_VC_RMS_Chx = {0,0,0,0}
-- 视在功率
local BL6552_Elect_VA_Chx = {0,0,0,0}
-- 电量
local BL6552_Elect_POWER_Chx = {0,0,0,0}
-- 芯片读写是否正常  1表示正常 2错误
local BL6552_WR_Flag_Chx = {0,0,0,0}
-- 输入缺相（各相电压）
local ZXTO_IN_A_Chx = {0,0,0,0}
local ZXTO_IN_B_Chx = {0,0,0,0}
local ZXTO_IN_C_Chx = {0,0,0,0}
-- 输出缺相（各项电流）
local ZXTO_OUT_A_Chx = {0,0,0,0}
local ZXTO_OUT_B_Chx = {0,0,0,0}
local ZXTO_OUT_C_Chx = {0,0,0,0}
-- 三相失衡
local I_SCALE_Chx = {0,0,0,0}
local I_SCALE_Chx_Num = {0,0,0,0} 
-- 过流过压标志
local VI_OVER_Chx = {0,0,0,0}
--------------------------------------------

--------------------------------------------
-- 计量中断队列
--------------------------------------------
local ExtimsgQuene = {} -- 外部中断事件的队列

local function Check_Event_Exist(ExtiChx) -- 检测事件是否已经在队列中(中断消抖)
    for i = 1, #ExtimsgQuene, 1 do
        if ExtiChx["tChx"] == ExtimsgQuene[i]["tChx"] then return true end
    end
    return false
end
local function ExtiinsertMsg(ExtiChx) -- 外部中断事件插入函数
    if Check_Event_Exist(ExtiChx)  == false then 
        table.insert(ExtimsgQuene, ExtiChx)
    end
end

local function waitForExtiMsg() 
    return #ExtimsgQuene > 0 
end

--供外部调用的的函数，读取 电流 电压 功率 的值，需求插入数据读取队列
local function BL6552_Chx(Event,Chx,Data,Tag)    --Chx = 1,event = "key" or "bl6553_irq" or "timer" or "mqtt"
    local t = 
    {        
        tEvent  =  Event,
        tChx    =  Chx, 
        tData   =  Data,
        tTag    =  Tag,
    }
    ExtiinsertMsg(t)
end

--更新 Chx 通道的 电压 电流 有功功率
local function BL6552_Update_Data_Chx(Chx,Data)
    if Data == 0 then
        BL6552_Elect_IA_RMS_Chx[Chx], BL6552_Elect_IB_RMS_Chx[Chx],
        BL6552_Elect_IC_RMS_Chx[Chx], BL6552_Elect_VA_RMS_Chx[Chx],
        BL6552_Elect_VB_RMS_Chx[Chx], BL6552_Elect_VC_RMS_Chx[Chx],
        BL6552_Elect_VA_Chx[Chx],BL6552_Elect_POWER_Chx[Chx] = _bl6552_spi.BL6552_Elect_Proc(Chx)
        log.debug("bl6552 Chx:", Chx, "data",BL6552_Elect_IA_RMS_Chx[Chx], BL6552_Elect_IB_RMS_Chx[Chx],
        BL6552_Elect_IC_RMS_Chx[Chx], BL6552_Elect_VA_RMS_Chx[Chx],
        BL6552_Elect_VB_RMS_Chx[Chx], BL6552_Elect_VC_RMS_Chx[Chx],
        BL6552_Elect_VA_Chx[Chx],BL6552_Elect_POWER_Chx[Chx])
    elseif Data == 1 then
        BL6552_Elect_IA_RMS_Chx[Chx], BL6552_Elect_IB_RMS_Chx[Chx],
        BL6552_Elect_IC_RMS_Chx[Chx], BL6552_Elect_VA_RMS_Chx[Chx],
        BL6552_Elect_VB_RMS_Chx[Chx], BL6552_Elect_VC_RMS_Chx[Chx],
        BL6552_Elect_VA_Chx[Chx],BL6552_Elect_POWER_Chx[Chx] = _bl6552_spi.BL6552_Elect_Proc(Chx)
        BL6552_Elect_POWER_Chx[Chx] = 0
        log.debug("bl6552 Chx:", Chx, "data",BL6552_Elect_IA_RMS_Chx[Chx], BL6552_Elect_IB_RMS_Chx[Chx],
        BL6552_Elect_IC_RMS_Chx[Chx], BL6552_Elect_VA_RMS_Chx[Chx],
        BL6552_Elect_VB_RMS_Chx[Chx], BL6552_Elect_VC_RMS_Chx[Chx],
        BL6552_Elect_VA_Chx[Chx],BL6552_Elect_POWER_Chx[Chx])
    end
end

----------------------------------------------------------------------
--电磁阀端口数据处理并且更新告警标志位
----------------------------------------------------------------------
local function _BL6552_Update_I_SCALE_Chx(Chx)
    I_SCALE_Chx[Chx] = 0
    if math.floor(((BL6552_Elect_IA_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IB_RMS_Chx[Chx] + 0.05)) * 100) < tonumber(fskv.get("I_SCALE_NUM_CHX_CONFIG")["_" .. tostring(Chx)]) then
        I_SCALE_Chx[Chx] = 1
        I_SCALE_Chx_Num[Chx] = math.floor(((BL6552_Elect_IA_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IB_RMS_Chx[Chx] + 0.05)) * 100)
    end
    if math.floor(((BL6552_Elect_IB_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IA_RMS_Chx[Chx] + 0.05)) * 100) < tonumber(fskv.get("I_SCALE_NUM_CHX_CONFIG")["_" .. tostring(Chx)]) then
        I_SCALE_Chx[Chx] = 1
        I_SCALE_Chx_Num[Chx] = math.floor(((BL6552_Elect_IB_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IA_RMS_Chx[Chx] + 0.05)) * 100)
    end
    if math.floor(((BL6552_Elect_IA_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IC_RMS_Chx[Chx] + 0.05)) * 100) < tonumber(fskv.get("I_SCALE_NUM_CHX_CONFIG")["_" .. tostring(Chx)]) then
        I_SCALE_Chx[Chx] = 1
        I_SCALE_Chx_Num[Chx] = math.floor(((BL6552_Elect_IA_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IC_RMS_Chx[Chx] + 0.05)) * 100)
    end
    if math.floor(((BL6552_Elect_IC_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IA_RMS_Chx[Chx] + 0.05)) * 100) < tonumber(fskv.get("I_SCALE_NUM_CHX_CONFIG")["_" .. tostring(Chx)]) then
        I_SCALE_Chx[Chx] = 1
        I_SCALE_Chx_Num[Chx] = math.floor(((BL6552_Elect_IC_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IA_RMS_Chx[Chx] + 0.05)) * 100)
    end
    if math.floor(((BL6552_Elect_IC_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IB_RMS_Chx[Chx] + 0.05)) * 100) < tonumber(fskv.get("I_SCALE_NUM_CHX_CONFIG")["_" .. tostring(Chx)]) then
        I_SCALE_Chx[Chx] = 1
        I_SCALE_Chx_Num[Chx] = math.floor(((BL6552_Elect_IC_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IB_RMS_Chx[Chx] + 0.05)) * 100)
    end
    if math.floor(((BL6552_Elect_IB_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IC_RMS_Chx[Chx] + 0.05)) * 100) < tonumber(fskv.get("I_SCALE_NUM_CHX_CONFIG")["_" .. tostring(Chx)]) then
        I_SCALE_Chx[Chx] = 1
        I_SCALE_Chx_Num[Chx] = math.floor(((BL6552_Elect_IB_RMS_Chx[Chx] + 0.05) / (BL6552_Elect_IC_RMS_Chx[Chx] + 0.05)) * 100)
    end
end

----------------------------------------------------------------------------------------------------
local function _BL6552_Update_ZXTO_IN_Chx(Chx)
    ZXTO_IN_A_Chx[Chx] = 0
    ZXTO_IN_B_Chx[Chx] = 0
    ZXTO_IN_C_Chx[Chx] = 0
    --------------------------------------
    -- 电压大小判断是否缺相
    if BL6552_Elect_VA_RMS_Chx[Chx] < _ZXTO_IN_NUM then ZXTO_IN_A_Chx[Chx] = 1 end
    --if BL6552_Elect_VB_RMS_Chx[Chx] < _ZXTO_IN_NUM then ZXTO_IN_B_Chx[Chx] = 1 end
    if BL6552_Elect_VC_RMS_Chx[Chx] < _ZXTO_IN_NUM then ZXTO_IN_C_Chx[Chx] = 1 end
    --------------------------------------
end

----------------------------------------------------------------------------------------------------
local function _BL6552_Update_ZXTO_OUT_Chx(Chx)
    ZXTO_OUT_A_Chx[Chx] = 0
    ZXTO_OUT_B_Chx[Chx] = 0
    ZXTO_OUT_C_Chx[Chx] = 0
    --------------------------------------
    -- 电压大小判断是否缺相
    if BL6552_Elect_IA_RMS_Chx[Chx] - BL6552_Elect_IB_RMS_Chx[Chx] < _ZXTO_OUT_NUM then ZXTO_OUT_A_Chx[Chx] = 1 end
    --if BL6552_Elect_IB_RMS_Chx[Chx] < _ZXTO_OUT_NUM then ZXTO_OUT_B_Chx[Chx] = 1 end
    if BL6552_Elect_IC_RMS_Chx[Chx] - BL6552_Elect_IB_RMS_Chx[Chx] < _ZXTO_OUT_NUM then ZXTO_OUT_C_Chx[Chx] = 1 end
    --------------------------------------
end

--------------------------更新输入缺相-输出缺相-三相失衡 标志
-- 各相电流比  如  AB BC CA 
local function BL6552_Update_I_SCALE_Chx(Chx, Data)
    if Data == 0 then  --清除标志
        I_SCALE_Chx[Chx] = 0
        I_SCALE_Chx_Num[Chx] = 0
    elseif Data == 1 then  --设置标志
        _BL6552_Update_I_SCALE_Chx(Chx)
    end
end
-- 各相电压 A和C的电压，由于参考电压B B电压为0 
local function BL6552_Update_ZXTO_IN_Chx(Chx, Data)
    if Data == 0 then  --清除标志
        ZXTO_IN_A_Chx[Chx] = 0
        ZXTO_IN_B_Chx[Chx] = 0
        ZXTO_IN_C_Chx[Chx] = 0
    elseif Data == 1 then  --设置标志
        _BL6552_Update_ZXTO_IN_Chx(Chx)
    end
end

-- 各相电流  A B C 的电流
local function BL6552_Update_ZXTO_OUT_Chx(Chx, Data)
    if Data == 0 then  --清除标志
        ZXTO_OUT_A_Chx[Chx] = 0
        ZXTO_OUT_B_Chx[Chx] = 0
        ZXTO_OUT_C_Chx[Chx] = 0
    elseif Data == 1 then  --设置标志
        _BL6552_Update_ZXTO_OUT_Chx(Chx)
    end
end

----------------------------------------------------------------------
--MQTT上报状态与告警函数（具体错误）
----------------------------------------------------------------------
local function _MQTT_Warn_I_SCALE_Chx(Chx)
    if fskv.get("I_SCALE_ENABLE_CHX_CONFIG")["_" .. tostring(Chx)] == "1" then  --确实报警使能
        if I_SCALE_Chx[Chx] == 1 then
            sys.publish("DeviceWarn_Status","Alert_SCALE", Chx, "0", "", "")
            if fskv.get("VVVF_ENABLE_CHX_CONFIG")["_" .. tostring(Chx)] == "0" then -- 非变频
                sys.publish("LED_Chx","AlertOP",Chx,0)
            end 
        end
    end
end
----------------------------------------------------------------------------------------------------
local function _MQTT_Warn_ZXTO_IN_Chx(Chx)
    -- 先报输入缺相（电压）
    if fskv.get("ZXTO_ENABLE_CHX_CONFIG")["_" .. tostring(Chx)] == "1" then -- 对应通道缺相判断使能
        if ZXTO_IN_A_Chx[Chx] == 1 then
            sys.publish("DeviceWarn_Status","Alert_ZXTO", Chx, "A", "", "")
            if fskv.get("VVVF_ENABLE_CHX_CONFIG")["_" .. tostring(Chx)] == "0" then -- 非变频
                sys.publish("LED_Chx","AlertOP",Chx,0)
            end 
        end
        if ZXTO_IN_B_Chx[Chx] == 1 then
            sys.publish("DeviceWarn_Status","Alert_ZXTO", Chx, "B", "", "")
            if fskv.get("VVVF_ENABLE_CHX_CONFIG")["_" .. tostring(Chx)] == "0" then -- 非变频
                sys.publish("LED_Chx","AlertOP",Chx,0)
            end 
        end
        if ZXTO_IN_C_Chx[Chx] == 1 then
            sys.publish("DeviceWarn_Status","Alert_ZXTO", Chx, "C", "", "")
            if fskv.get("VVVF_ENABLE_CHX_CONFIG")["_" .. tostring(Chx)] == "0" then -- 非变频
                sys.publish("LED_Chx","AlertOP",Chx,0)
            end 
        end         
    end
end
----------------------------------------------------------------------------------------------------
local function _MQTT_Warn_ZXTO_OUT_Chx(Chx)
    if ZXTO_IN_A_Chx[Chx] == 1 or ZXTO_IN_B_Chx[Chx] == 1 or ZXTO_IN_C_Chx[Chx] == 1 then
        -- 输出缺相（电流比例去判断）
        if fskv.get("ZXTO_ENABLE_CHX_CONFIG")["_" .. tostring(Chx)] == "1" then  --确实报警使能
            sys.publish("DeviceWarn_Status","Alert_ZXTO", Chx, "0", "", "")
            if fskv.get("VVVF_ENABLE_CHX_CONFIG")["_" .. tostring(Chx)] == "0" then -- 非变频
                -- 关闭电磁阀 - 事件 同统一为 ： Event = "AlertOP"
                sys.publish("LED_Chx","AlertOP",Chx,0)
            end
        end
    end
end
----------------------------------------------------------------------------------------------------
local function _MQTT_Warn_VI_OVER_Chx(Chx)
    -- 过压 过流报警
    if fskv.get("IV_NUM_ENABLE_CHX_CONFIG")["_" .. tostring(Chx)] == "1" then -- 对应通道缺相判断使能
        if BL6552_Elect_VA_RMS_Chx[Chx] > fskv.get("V_NUM_CHX_CONFIG")["_" .. tostring(Chx)] then
            sys.publish("DeviceWarn_Status","Alert_VF", Chx, tostring(BL6552_Elect_VA_RMS_Chx[Chx]), "", "")
            sys.publish("LED_Chx","AlertOP",Chx,0)
        end

        if BL6552_Elect_IA_RMS_Chx[Chx] > fskv.get("I_NUM_CHX_CONFIG")["_" .. tostring(Chx)] then
            sys.publish("DeviceWarn_Status","Alert_IF", Chx, tostring(BL6552_Elect_IA_RMS_Chx[Chx]), "", "")
            sys.publish("LED_Chx","AlertOP",Chx,0)
        end

    end
end
--------------------------发送输入缺相-输出缺相-三相失衡 告警
-- 各相电流比  如  AB BC CA 
local function MQTT_Warn_I_SCALE_Chx(Chx)
    _MQTT_Warn_I_SCALE_Chx(Chx)
end

-- 各相电压 A和C的电压，由于参考电压B B电压为0 
local function MQTT_Warn_ZXTO_IN_Chx(Chx)
    _MQTT_Warn_ZXTO_IN_Chx(Chx)
end

-- 各相电流  A B C 的电流
local function MQTT_Warn_ZXTO_OUT_Chx(Chx)
    _MQTT_Warn_ZXTO_OUT_Chx(Chx)
end

-- 各电磁阀过流过压告警
local function MQTT_Warn_ZXTO_OUT_Chx(Chx)
    _MQTT_Warn_ZXTO_OUT_Chx(Chx)
end

-- 各电磁阀过流过压告警
local function MQTT_Warn_VI_OVER_Chx(Chx)
    _MQTT_Warn_VI_OVER_Chx(Chx)
end
----------------------------------------------------------------------
--MQTT上报告警函数
----------------------------------------------------------------------
-- BL6552-告警处理函数
local function BL6552_Mqtt_Warn_Chx(Event,Chx,Data,Tag)
    if Event == "SysOP" or Event == "SvrOP" or  Event == "KeyOP" or Event == "TimeOP" then  
        -- MQTT 处理告警事件
        MQTT_Warn_ZXTO_IN_Chx(Chx)
        MQTT_Warn_ZXTO_OUT_Chx(Chx)
    end

    if Event == "GetChx" then  
        MQTT_Warn_I_SCALE_Chx(Chx)
    end

    if Event == "Prof_IV" then  ---过压过流中断
        -- 告警  安装上面的写法  20231230  待完成
        MQTT_Warn_VI_OVER_Chx(Chx)
    end 

end

----------------------------------------------------------------------
--MQTT上报状态函数
----------------------------------------------------------------------
local function BL6552_Data_Chx(Chx)
    return  BL6552_Elect_IA_RMS_Chx[Chx], BL6552_Elect_IB_RMS_Chx[Chx],
            BL6552_Elect_IC_RMS_Chx[Chx], BL6552_Elect_VA_RMS_Chx[Chx],
            BL6552_Elect_VB_RMS_Chx[Chx], BL6552_Elect_VC_RMS_Chx[Chx],
            BL6552_Elect_VA_Chx[Chx],BL6552_Elect_POWER_Chx[Chx]
end
-- BL6552-上报状态函数
local function BL6552_Mqtt_Report_Chx(Event,Chx,Data,Tag)
        -- MQTT 处理事件
        local _data
        local _IA,_IB,_IC,_VA,_VB,_VC,_W,_P = BL6552_Data_Chx(Chx)
        if Data == 1 then
            _data = string.format("%.2f_%.2f_%.2f_%.2f_%.2f_%.2f_%.2f",_IA,_IB,_IC,_VA,_VB,_VC,_W) -- 保存数据
            sys.publish("DeviceResponse_Status",Event, Chx, _data, "1", Tag)   -----------
        elseif Data == 0 then
            _data = string.format("%.2f",_P) -- 保存数据
            sys.publish("DeviceResponse_Status",Event, Chx, _data, "0", Tag)    -----------
        end
end

----------------------------------------------------------------------
--  BL6552 -> MQTT  统一处理函数
----------------------------------------------------------------------
local function Update_Chx_Status(Event, Chx, Data, Tag) 
    if Event == "SysOP" or Event == "SvrOP" or  Event == "KeyOP" or Event == "TimeOP" or Event == "GetChx" then  
        if Chx == 1 or Chx == 2 or Chx == 3 or Chx == 4 then
            if Tag == "0" or Tag == "1" or Tag == "2" then     --上报状态方式（Tag）--后续出现其他的情况，添加处理函数即可
                if Data == 1 or Data == 0 then
                    BL6552_Mqtt_Report_Chx(Event,Chx,Data,Tag)
                    BL6552_Mqtt_Warn_Chx(Event,Chx,Data,Tag)    
                end
            end
        end
    end
end
-------------------------------------------- 【处理】外部事件 --------------------------------------------
sys.taskInit(function()
    local ExtiChx
    local result
    --等待BL6552芯片初始化完成
    result,BL6552_WR_Flag_Chx[1],BL6552_WR_Flag_Chx[2],BL6552_WR_Flag_Chx[3],BL6552_WR_Flag_Chx[4] = sys.waitUntil("bl6552_enable")
    log.info("BL6552事件处理开始!")
    log.info("BL6552_WR_Flag_Chx:",BL6552_WR_Flag_Chx[1],BL6552_WR_Flag_Chx[2],BL6552_WR_Flag_Chx[3],BL6552_WR_Flag_Chx[4])
    while true do
        if waitForExtiMsg() then
            while #ExtimsgQuene > 0 do -- 数组大于零？
                sys.wait(5)  -- GIAO
                local tData = table.remove(ExtimsgQuene, 1) -- 取出并删除一个元素  

                log.info("BL6552事件处理",tData.tEvent,tData.tChx,tData.tData,tData.tTag)
                -- 参数 判断
                if BL6552_WR_Flag_Chx[tData.tChx] == 1 then --对应芯片正常
                    BL6552_Update_Data_Chx(tData.tChx,tData.tData)     -- 【1】更新 电压 电流 有效功率
                    --设置对应告警标志
                    BL6552_Update_I_SCALE_Chx(tData.tChx,tData.tData)  -- 【2.1】更新是否三相失衡
                    BL6552_Update_ZXTO_IN_Chx(tData.tChx,tData.tData)  -- 【2.2】更新是否输入缺相
                    BL6552_Update_ZXTO_OUT_Chx(tData.tChx,tData.tData) -- 【2.3】更新是否输出缺相
    
                    -- 【3】以下函数都需要放置在Update_Chx_Status 中  具体的端口更新分为 服务器修改配置  5分钟定时上报 （按键，服务器，定时器，告警）控制电磁阀
                    --三相失衡 输出缺相 输入缺相   具体需要报什么警告  Tag 判断
                    Update_Chx_Status(tData.tEvent,tData.tChx,tData.tData,tData.tTag)
                elseif BL6552_WR_Flag_Chx[tData.tChx] == 2 then
                    log.info("BL6552 --------INIT error!!!  ",tData.tEvent,tData.tChx,tData.tData,tData.tTag)
                end
            end
        else
            sys.wait(200)
        end
    end
end)


-------------------------------------------- 【接收】外部事件 --------------------------------------------
sys.taskInit(function()
    sys.wait(2000) -- 等待2S再处理数据
    ExtimsgQuene = {} -- 清空队列
    log.info("BL6552_Event_Start!")
    while true do
        local result,Event,Chx,Data,Tag = sys.waitUntil("BL6552_Chx")
        if result then
            BL6552_Chx(Event,Chx,Data,Tag)
        end
    end
end)

--------------------------------------------
log.info("shell -- file -- _bl6552_data -- end")
------供外部文件调用的函数
return {
    BL6552_Chx = BL6552_Chx
}