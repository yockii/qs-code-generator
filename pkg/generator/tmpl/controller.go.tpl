package controller

import (
    "github.com/gofiber/fiber/v2"
    "github.com/yockii/qscore/pkg/constant"
    "github.com/yockii/qscore/pkg/domain"
    "github.com/yockii/qscore/pkg/logger"

    "{{ .application.Package }}/internal/model"
    "{{ .application.Package }}/internal/service"
)

var {{.table.Name | title }}Controller = new({{.table.Name | untitle }}Controller)
type {{.table.Name | untitle }}Controller struct {}

func (c *{{.table.Name | untitle }}Controller) Add(ctx *fiber.Ctx) error {
    instance := new(model.{{.table.Name | title }})
    if err := ctx.BodyParser(instance); err != nil {
        logger.Error(err)
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeBodyParse,
            Msg: "参数解析失败!",
        })
    }

    // 处理必填
    msg := ""
    {{ range .table.Columns -}}
        {{if (not .Nullable) -}}
            if instance.{{ .Name | title }} == {{ if (eq .Type 1) }}""{{ else if (eq .Type 2) }}0{{ else }}nil{{ end }} {
                msg += "{{ .DisplayName }}/"
            }
        {{- end }}
    {{- end }}

    if msg != "" {
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeLackOfField,
            Msg:  msg + "必须提供",
        })
    }

    duplicated, success, err := service.{{ .table.Name | title }}Service.Add(instance)
    if err != nil {
        logger.Error(err)
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeService,
            Msg:  "服务出现异常",
        })
    }
    if duplicated {
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeDuplicate,
            Msg:  "有重复记录",
        })
    }
    if success {
        return ctx.JSON(&domain.CommonResponse{Data: instance})
    }
    return ctx.JSON(&domain.CommonResponse{
        Code: constant.ErrorCodeUnknown,
        Msg:  "服务出现异常",
    })
}

func (c *{{ .table.Name | untitle }}Controller) Delete(ctx *fiber.Ctx) error {
    instance := new(model.{{ .table.Name | title }})
    if err := ctx.QueryParser(instance); err != nil {
        logger.Error(err)
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeBodyParse,
            Msg: "参数解析失败!",
        })
    }
    if instance.Id == "" {
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeLackOfField,
            Msg:  "ID必须提供",
        })
    }
    deleted, err := service.{{ .table.Name | title }}Service.Remove(instance)
    if err != nil {
        logger.Error(err)
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeService,
            Msg:  "服务出现异常",
        })
    }
    if deleted {
        return ctx.JSON(&domain.CommonResponse{})
    }
    return ctx.JSON(&domain.CommonResponse{
        Msg: "无数据被删除",
        Data: false,
    })
}

func (c *{{ .table.Name | untitle }}Controller) Update(ctx *fiber.Ctx) error {
    instance := new(model.{{ .table.Name | title }})
    if err := ctx.BodyParser(instance); err != nil {
        logger.Error(err)
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeBodyParse,
            Msg: "参数解析失败!",
        })
    }
    if instance.Id == "" {
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeLackOfField,
            Msg:  "ID必须提供",
        })
    }
    updated, err := service.{{ .table.Name | title }}Service.Update(instance)
    if err != nil {
        logger.Error(err)
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeService,
            Msg:  "服务出现异常",
        })
    }
    if updated {
        return ctx.JSON(&domain.CommonResponse{})
    }
    return ctx.JSON(&domain.CommonResponse{
        Msg: "无数据被更新",
        Data: false,
    })
}

func (c *{{ .table.Name | untitle }}Controller) Paginate(ctx *fiber.Ctx) error {
    pr := new(model.{{ .table.Name | title }}Request)
    if err := ctx.QueryParser(pr); err != nil {
        logger.Error(err)
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeBodyParse,
            Msg: "参数解析失败!",
        })
    }
    limit, offset, orderBy, err := parsePaginationInfoFromQuery(ctx)
    if err != nil{
        logger.Error(err)
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeBodyParse,
            Msg: "参数解析失败!",
        })
    }

    timeRangeMap := make(map[string]*domain.TimeCondition)
    {{ range .table.Columns }}
        {{- if (eq .Type 3) -}}
    if {{ .Name | title}}Range != nil {
        timeRangeMap["{{ .Name | snakecase}}"] = &domain.TimeCondition{
            Start: pr.{{ .Name | title}}Range.Start,
            End:   pr.{{ .Name | title}}Range.End,
        }
    }
        {{- end -}}
    {{ end }}
    {{ if .table.RecordUpdateTime }}
    if pr.UpdateTimeRange != nil {
        timeRangeMap["update_time"] = &domain.TimeCondition{
            Start: pr.UpdateTimeRange.Start,
            End:   pr.UpdateTimeRange.End,
        }
    }
    {{ end }}
    {{ if .table.RecordCreateTime }}
    if pr.CreateTimeRange != nil {
        timeRangeMap["create_time"] = &domain.TimeCondition{
            Start: pr.CreateTimeRange.Start,
            End:   pr.CreateTimeRange.End,
        }
    }
    {{ end }}

    total, list, err := service.{{ .table.Name | title }}Service.PaginateBetweenTimes(pr.{{ .table.Name | title }}, limit, offset, orderBy, timeRangeMap)
    if err != nil {
        logger.Error(err)
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeService,
            Msg:  "服务出现异常",
        })
    }
    return ctx.JSON(&domain.CommonResponse{Data: &domain.Paginate{
        Total:  total,
        Offset: offset,
        Limit:   limit,
        Items:  list,
    }})
}

func (c *{{ .table.Name | untitle }}Controller) Get(ctx *fiber.Ctx) error {
    instance := new(model.{{ .table.Name | title }})
    var err error
    if err = ctx.QueryParser(instance); err != nil {
        logger.Error(err)
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeBodyParse,
            Msg: "参数解析失败!",
        })
    }
    instance, err = service.{{ .table.Name | title }}Service.Get(instance)
    if err != nil {
        logger.Error(err)
        return ctx.JSON(&domain.CommonResponse{
            Code: constant.ErrorCodeService,
            Msg:  "服务出现异常",
        })
    }
    return ctx.JSON(&domain.CommonResponse{
        Data: instance,
    })
}