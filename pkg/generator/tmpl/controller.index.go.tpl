package controller

import (
    "strconv"
    "strings"

    "github.com/gofiber/fiber/v2"
    "github.com/yockii/qscore/pkg/server"
    "github.com/yockii/qscore/pkg/util"
)

func InitRouter() {
    // 登录
    server.Post("/login", UserController.Login)

    {{range .application.Tables}}
    // {{.Name | title}}
    server.StandardRouter(
        "/{{.Name | untitle}}",
        {{.Name | title}}Controller.Add,
        {{.Name | title}}Controller.Update,
        {{.Name | title}}Controller.Delete,
        {{.Name | title}}Controller.Get,
        {{.Name | title}}Controller.Paginate,
    )
    {{end}}

    // Dict
    server.StandardRouter(
        "/dict",
        DictController.Add,
        DictController.Update,
        DictController.Delete,
        DictController.Get,
        DictController.Paginate,
    )
    // Resource
    server.StandardRouter(
        "/resource",
        ResourceController.Add,
        ResourceController.Update,
        ResourceController.Delete,
        ResourceController.Get,
        ResourceController.Paginate,
    )
    // Role
    server.StandardRouter(
        "/role",
        RoleController.Add,
        RoleController.Update,
        RoleController.Delete,
        RoleController.Get,
        RoleController.Paginate,
    )
    // User
    server.StandardRouter(
        "/user",
        UserController.Add,
        UserController.Update,
        UserController.Delete,
        UserController.Get,
        UserController.Paginate,
    )
}


func parsePaginationInfoFromQuery(ctx *fiber.Ctx) (size, offset int, orderBy string, err error) {
    sizeStr := ctx.Query("size", "10")
    offsetStr := ctx.Query("offset", "0")
    size, err = strconv.Atoi(sizeStr)
    if err != nil {
        return
    }
    offset, err = strconv.Atoi(offsetStr)
    if err != nil {
        return
    }
    if size < -1 || size > 1000 {
        size = 10
    }
    if offset < -1 {
        offset = 0
    }
    orderBy = ctx.Query("orderBy") // orderBy=xxx-desc,yyy-asc,zzz
    if orderBy != "" {
        obs := strings.Split(orderBy, ",")
        ob := ""
        for _, s := range obs {
            kds := strings.Split(s, "-")
            ob += ", " + util.SnakeString(strings.TrimSpace(kds[0]))
            if len(kds) == 2 {
                d := strings.ToLower(kds[1])
                if d == "desc" {
                    ob += " DESC"
                }
            }
        }
        orderBy = ob
    }
    return
}