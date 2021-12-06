package main

import (
    "github.com/yockii/qscore/pkg/authorization"
    "github.com/yockii/qscore/pkg/cache"
    "github.com/yockii/qscore/pkg/config"
    "github.com/yockii/qscore/pkg/database"
    "github.com/yockii/qscore/pkg/logger"
    "github.com/yockii/qscore/pkg/server"

    "{{ .application.Package }}/internal/controller"
    "{{ .application.Package }}/internal/initial"
)

func main() {
    {
        // 初始化配置项(已引入自动初始化)
        // 使用默认即可，默认是在conf/config.toml
        logger.SetLevel(config.GetString("log.level"))
        logger.SetReportCaller(config.GetBool("log.showCode"))
        logger.SetLogDir(config.GetString("log.dir"), config.GetInt("log.rotate"))
    }
    {
        // 初始化数据库，默认使用 database/ driver、host、user、password、db、port、prefix、showSql    log/ level
        database.InitSysDB()
        defer database.Close()
    }
    {
        // 初始化缓存
        if config.GetBool("redis.enable") {
            cache.UseRedis(
                config.GetString("redis.prefix"),
                config.GetString("redis.host"),
                config.GetString("redis.password"),
                config.GetInt("redis.port"),
                config.GetInt("redis.maxIdle"),
                config.GetInt("redis.maxActive"),
            )
            defer cache.Close()
        } else {
            cache.UseMemory()
            defer cache.Close()
        }
    }
    authorization.Init()
    // 初始化数据
    initial.InitData()

    // 启动服务
    controller.InitRouter()
    logger.Error(server.Start(":" + config.GetString("server.port")))
}
