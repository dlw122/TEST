log.info("shell -- file -- _timer -- start")

-- 在定时器开启电磁阀的时候标志位为1，如果有其他单元有关闭电磁阀，此区间的定时器关闭失效标志位为 0  
local Elec_Timer_Chx_Flag = {0,0,0,0}


local function Elec_Timer_Chx_Clear(Chx)
    Elec_Timer_Chx_Flag[Chx] = 0
end

---------------------------------------------------
-- 设备时间
---------------------------------------------------
local Server_time = {year = 2023, month = 12, day = 08, hour = 08, min = 08, sec = 08}

--输入时间字符串 "2023/08/15,10:07:00"
local function Set_Time(time_sync)
    Server_time["year"]  = tonumber(string.sub(time_sync, 1 , 4 ))
    Server_time["month"] = tonumber(string.sub(time_sync, 6 , 7 ))
    Server_time["day"]   = tonumber(string.sub(time_sync, 9 , 10))
    Server_time["hour"]  = tonumber(string.sub(time_sync, 12, 13))
    Server_time["min"]   = tonumber(string.sub(time_sync, 15, 16))
    Server_time["sec"]   = tonumber(string.sub(time_sync, 18, 19))
end

---------------------------------------------------
-- 控制电磁阀定时开关
---------------------------------------------------
local function _Timer_Control_Chx(Chx,time)

    local time_num        = 0  --第几个定时单元
    local time_open_data  = "" --第几个定时单元定时开启数据
    local time_close_data = "" --第几个定时单元定时关闭数据

    if fskv.get("Time_ENABLE_CHX_CONFIG")[Chx] == "1" then

        --时间结构为 "10:00" 5字符
        local Start_time = fskv.get("START_Time_CHX_CONFIG")[Chx] --定时器开启时间序
        local Close_time = fskv.get("CLOSE_Time_CHX_CONFIG")[Chx] --定时器关闭时间序

        local Time_OP = "TimeOP"  -- 驱动电磁阀单元符号

        if (string.len(Start_time) / 5) ~= 0 and (string.len(Start_time) % 5) == 0 then
            time_num = string.len(Start_time) / 5 -- 获取定时器开启电磁阀的时间数据

            for i = 1, time_num, 1 do
                time_open_data = string.sub(Start_time,(i - 1) * 5 + 1, i * 5)
                if tonumber(string.sub(time_open_data, 1, 5)) == tonumber(string.sub(time, 1, 5)) then -- 时间相等
                    -- 定时器开启电磁阀
                    sys.publish("LED_Chx","TimeOP",Chx,1)
                    -- 使能 - 定时关闭
                    Elec_Timer_Chx_Flag[Chx] = 1
                end
            end
        end

        if (string.len(Close_time) / 5) ~= 0 and (string.len(Close_time) % 5) == 0 then
            time_close_data = string.sub(Close_time,(time_num - 1) * 5 + 1, time_num * 5)
        end
        
        if Elec_Timer_Ch1_Flag == 1 then
            if tonumber(string.sub(time_close_data, 1, 5)) == tonumber(string.sub(time, 1, 5)) then -- 时间相等
                -- 失能 - 定时关闭
                Elec_Timer_Chx_Flag[Chx] = 0
                -- 定时 关闭时间 关闭电磁阀 
                sys.publish("LED_Chx","TimeOP",Chx,0)
            end
        end
    end
end

---------------------------------------------------
-- 控制电磁阀所有定时开关
---------------------------------------------------
local function Timer_Control_Chx(server_time)
    -- 判断时间已经同步过
    sys.waitUntil("Mqtt_Set_Timer")
    while true do
        -- 获取当前时间
        local t = server_time
        local time = string.format("%04d/%02d/%02d,%02d:%02d", t["year"],t["month"], t["day"], t["hour"], t["min"]) 

        _Timer_Control_Chx(1,time)
        _Timer_Control_Chx(2,time)
        _Timer_Control_Chx(3,time)
        _Timer_Control_Chx(4,time)
        sys.wait(10000)
    end

end

--Mqtt 设置同步更新时间
local function Mqtt_Set_Timer_Control(server_time) 
    while true do
        local res,time_sync = sys.waitUntil("TimeSync") -- 等待服务器同步本机时间（至少同步一次）
        if res == true then
            Set_Time(time_sync)
            sys.publish("Mqtt_Set_Timer") -- 时间同步设置
        end
    end
end

--本地计时 更新时间
local function Online_Set_Timer_Control(server_time) 
    sys.waitUntil("Mqtt_Set_Timer") -- 等待服务器同步本机时间（初始化时间）
    while true do
        sys.wait(1000)  --等待1S 后续也可以计数增加1S
        local t = server_time-- 获取当前时间
        -- 时间 + 1S
        t["sec"] = t["sec"] + 1
        if t["sec"] > 59 then
            t["sec"] = 0
            t["min"] = t["min"] + 1
            if t["min"] > 59 then
                t["min"] = 0
                t["hour"] = t["hour"] + 1
                if t["hour"] > 23 then t["hour"] = 0 end
            end
        end
        --本地更新时间
        Set_Time(string.format("%04d/%02d/%02d,%02d:%02d:%02d", t["year"],t["month"], t["day"], t["hour"], t["min"],t["sec"]))
    end
end

---------------------------------------信号触发顺序---------------------------------------
--【1】 TimeSync  Mqtt更新时间
--【2】 Mqtt_Set_Timer  启动本地时间更新  启动定时功能

sys.taskInit(Timer_Control_Chx,Server_time)--保证断网时也能正常处理
sys.taskInit(Mqtt_Set_Timer_Control,Server_time)--保证断网时也能正常处理
sys.taskInit(Mqtt_Set_Timer_Control,Server_time)--保证断网时也能正常处理

log.info("shell -- file -- _timer -- end")
-- 用户代码已结束---------------------------------------------
------供外部文件调用的函数
return {
    Elec_Timer_Chx_Clear = Elec_Timer_Chx_Clear,
} 
