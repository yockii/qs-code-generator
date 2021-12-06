package controller

import (
	"github.com/gofiber/fiber/v2"
	"github.com/yockii/qscore/pkg/constant"
	"github.com/yockii/qscore/pkg/domain"
	"github.com/yockii/qscore/pkg/logger"
	
	"{{.application.Package }}/internal/service"
)

var UserController = new(userController)
type userController struct {}

func (c *userController) Login(ctx *fiber.Ctx) error {
	instance := new(domain.User)
	if err := ctx.BodyParser(instance); err != nil {
		logger.Error(err)
		return ctx.JSON(&domain.CommonResponse{
			Code: constant.ErrorCodeBodyParse,
			Msg: "参数解析失败!",
		})
	}
	if instance.Username == "" || instance.Password == "" {
		return ctx.JSON(&domain.CommonResponse{
			Code: constant.ErrorCodeLackOfField,
			Msg:  "用户名及密码必须提供",
		})
	}
	
	token, err := service.UserService.Login(instance)
	if err != nil {
		logger.Error(err)
		return ctx.JSON(&domain.CommonResponse{
			Code: constant.ErrorCodeService,
			Msg:  "服务出现异常",
		})
	}
	if token == "" {
		return ctx.JSON(&domain.CommonResponse{
			Code: constant.ErrorCodeNotFound,
			Msg: "登录失败",
		})
	}
	return ctx.JSON(&domain.CommonResponse{
		Data: token,
	})
}

func (c *userController) Add(ctx *fiber.Ctx) error {
	instance := new(domain.User)
	if err := ctx.BodyParser(instance); err != nil {
		logger.Error(err)
		return ctx.JSON(&domain.CommonResponse{
			Code: constant.ErrorCodeBodyParse,
			Msg: "参数解析失败!",
		})
	}
	
	// 处理必填
	if instance.Username == "" || instance.Password == "" {
		return ctx.JSON(&domain.CommonResponse{
			Code: constant.ErrorCodeLackOfField,
			Msg:  "用户名/密码必须提供",
		})
	}
	
	duplicated, success, err := service.UserService.Add(instance)
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

func (c *userController) Delete(ctx *fiber.Ctx) error {
	instance := new(domain.User)
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
	deleted, err := service.UserService.Remove(instance)
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

func (c *userController) Update(ctx *fiber.Ctx) error {
	instance := new(domain.User)
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
	updated, err := service.UserService.Update(instance)
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

func (c *userController) Paginate(ctx *fiber.Ctx) error {
	pr := new(domain.UserRequest)
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
	
	total, list, err := service.UserService.PaginateBetweenTimes(pr.User, limit, offset, orderBy, timeRangeMap)
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

func (c *userController) Get(ctx *fiber.Ctx) error {
	instance := new(domain.User)
	var err error
	if err = ctx.QueryParser(instance); err != nil {
		logger.Error(err)
		return ctx.JSON(&domain.CommonResponse{
			Code: constant.ErrorCodeBodyParse,
			Msg: "参数解析失败!",
		})
	}
	instance, err = service.UserService.Get(instance)
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