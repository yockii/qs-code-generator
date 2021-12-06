package controller

import (
	"github.com/gofiber/fiber/v2"
	"github.com/yockii/qscore/pkg/constant"
	"github.com/yockii/qscore/pkg/domain"
	"github.com/yockii/qscore/pkg/logger"
	
	"{{.application.Package}}/internal/service"
)

var RoleController = new(roleController)
type roleController struct {}

func (c *roleController) Add(ctx *fiber.Ctx) error {
	instance := new(domain.Role)
	if err := ctx.BodyParser(instance); err != nil {
		logger.Error(err)
		return ctx.JSON(&domain.CommonResponse{
			Code: constant.ErrorCodeBodyParse,
			Msg: "参数解析失败!",
		})
	}
	
	// 处理必填
	if instance.RoleName == "" {
		return ctx.JSON(&domain.CommonResponse{
			Code: constant.ErrorCodeLackOfField,
			Msg:  "角色名必须提供",
		})
	}
	
	duplicated, success, err := service.RoleService.Add(instance)
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

func (c *roleController) Delete(ctx *fiber.Ctx) error {
	instance := new(domain.Role)
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
	deleted, err := service.RoleService.Remove(instance)
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

func (c *roleController) Update(ctx *fiber.Ctx) error {
	instance := new(domain.Role)
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
	updated, err := service.RoleService.Update(instance)
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

func (c *roleController) Paginate(ctx *fiber.Ctx) error {
	pr := new(domain.RoleRequest)
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
	if pr.CreateTimeRange != nil {
		timeRangeMap["create_time"] = &domain.TimeCondition{
			Start: pr.CreateTimeRange.Start,
			End:   pr.CreateTimeRange.End,
		}
	}
	
	total, list, err := service.RoleService.PaginateBetweenTimes(pr.Role, limit, offset, orderBy, timeRangeMap)
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

func (c *roleController) Get(ctx *fiber.Ctx) error {
	instance := new(domain.Role)
	var err error
	if err = ctx.QueryParser(instance); err != nil {
		logger.Error(err)
		return ctx.JSON(&domain.CommonResponse{
			Code: constant.ErrorCodeBodyParse,
			Msg: "参数解析失败!",
		})
	}
	instance, err = service.RoleService.Get(instance)
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