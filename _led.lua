log.info("shell -- file -- led -- start")

--------------------------------------------
-- 电磁阀状态定义、写、读
--------------------------------------------
-- 电磁阀的状态
local Electromagnetic_Chx = {0,0,0,0}

--赋值开发板LED引脚编号
local LED_INIT = {gpio.setup(22, 0, gpio.PULLUP),gpio.setup(20, 0, gpio.PULLUP),gpio.setup(25, 0, gpio.PULLUP),gpio.setup(26, 0, gpio.PULLUP)}
local LEDX = {22,20,25,26}
-- 下面进行电磁阀 IO口初始化
local OUT_INIT = {gpio.setup(31, 0, gpio.PULLUP),gpio.setup(30, 0, gpio.PULLUP),gpio.setup(29, 0, gpio.PULLUP),gpio.setup(21, 0, gpio.PULLUP)}
local OUTX = {31,30,29,21}
-- 设置电磁阀状态
local function Set_Electromagnetic_ChX(ChX, data)
        Electromagnetic_Chx[ChX] = data
        gpio.set(LEDX[ChX], Electromagnetic_Chx[ChX])
        gpio.set(OUTX[ChX], Electromagnetic_Chx[ChX])
        log.warn("LED开关控制","ChX",LEDX[ChX],"DATA",Electromagnetic_Chx[ChX])
end

-- 获取电磁阀状态
local function Get_Electromagnetic_ChX(ChX)
    return Electromagnetic_Chx[ChX]
end

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
local function LED_Chx(Event,Chx,Data)    --Chx = 1,event = "key" or "bl6553_irq" or "timer" or "mqtt"
    local t = 
    {
        tEvent =  Event,
        tChx   =  Chx, 
        tData  =  Data,
    }
    ExtiinsertMsg(t)
end

sys.taskInit(function()

    while true do
        if waitForExtiMsg() then
            
            while #ExtimsgQuene > 0 do -- 数组大于零？
                sys.wait(5) -- GIAO
                local tData = table.remove(ExtimsgQuene, 1) -- 取出并删除一个元素 
                    log.info("LED事件处理", tData.tEvent, tData.tChx, tData.tData)

                    -- 告警 -> 关闭电磁阀  （）
                    if tData.tEvent == "AlertOP" then                                             
                        Set_Electromagnetic_ChX(tData.tChx,tData.tData) -- 更新电磁阀与LED状态
                        sys.publish("DeviceWarn_Status",tData.tEvent, 0, tData.tData, "", "")  
                    end

                    -- 控制电磁阀  
                    if tData.tEvent == "SysOP" or tData.tEvent == "SvrOP" or tData.tEvent == "KeyOP" or tData.tEvent == "TimeOP" then                                           
                        _timer.Elec_Timer_Chx_Clear(tData.tChx) --定时器标志清除
                        Set_Electromagnetic_ChX(tData.tChx,tData.tData) -- 更新电磁阀与LED状态
                        sys.publish("DeviceResponse_Status",tData.tEvent, tData.tChx, tData.tData, "", "")  
                        --sys.timerStart(sys.publish, 2100, "BL6552_Chx", tData.tEvent, tData.tChx, tData.tData, "1")
                        --sys.timerStart(sys.publish, 62100,"BL6552_Chx", tData.tEvent, tData.tChx, tData.tData, "2")
                    end
                    --输出开启时状态及功率数据上传

            end
        else
            sys.wait(200)
        end
    end
end)

local Self_Check = 0


---------------------------------------------------
-- 保留的电磁阀状态
---------------------------------------------------
sys.taskInit(function()
    sys.wait(20000) -- 等待2S再处理数据
    log.info("ElE_CHX_Save_Start!","10s")
    while true do
        fskv.set("ElE_CHX", {tostring(Electromagnetic_Chx[1]),tostring(Electromagnetic_Chx[2]),tostring(Electromagnetic_Chx[3]),tostring(Electromagnetic_Chx[4])})
        sys.wait(10000)
    end
end)

-------------------------------------------- 【接收】外部事件 --------------------------------------------
sys.taskInit(function()
    sys.wait(2000) -- 等待2S再处理数据
    ExtimsgQuene = {} -- 清空队列
    log.info("LED_Event_Start!")
    while true do
        local result,Event,Chx,Data = sys.waitUntil("LED_Chx")
        if result then
            LED_Chx(Event,Chx,Data)
        end
    end
end)

log.info("shell -- file -- led -- end")
-- 用户代码已结束---------------------------------------------
------供外部文件调用的函数
return {
    Get_Electromagnetic_ChX = Get_Electromagnetic_ChX,
    Set_Electromagnetic_ChX = Set_Electromagnetic_ChX,
    LED_Chx = LED_Chx
}