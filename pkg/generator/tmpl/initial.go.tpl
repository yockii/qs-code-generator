package initial

import (
    "github.com/yockii/qscore/pkg/authorization"
    "github.com/yockii/qscore/pkg/constant"
    "github.com/yockii/qscore/pkg/database"
    "github.com/yockii/qscore/pkg/domain"
    "github.com/yockii/qscore/pkg/logger"
    "github.com/yockii/qscore/pkg/util"

    "{{.application.Package }}/internal/model"
    "{{.application.Package }}/internal/service"
)

func InitData() {
    syncDB()
    checkInitialAuthorizationData()
}

func checkInitialAuthorizationData() {
    need := false
    role := &domain.Role{RoleName: constant.DefaultRoleName}
    has, err := database.DB.Get(role)
    if err != nil {
        logger.Error(err)
        return
    }
    if !has {
        role.Id = domain.RoleIdPrefix + util.GenerateDatabaseID()
        _, err = database.DB.Insert(role)
        if err != nil {
            logger.Error(err)
            return
        }
        need = true
    }
    // 处理用户
    admin := &domain.User{Username: constant.DefaultUsername}
    has, err = database.DB.Get(admin)
    if err != nil {
        logger.Error(err)
        return
    }
    if !has {
        admin.Password = "123456"
        _, _, err = service.UserService.Add(admin)
        if err != nil {
            logger.Error(err)
            return
        }
        need = true
    }
    // 若角色或用户不存在，则处理用户角色关系
    if need {
        _, err = authorization.AddSubjectGroup(admin.Id, role.Id, "")
        if err != nil {
            logger.Error(err)
            return
        }
    }
    // 超级管理员赋权
    authorization.SetSuperAdmin(role.Id)
}

func syncDB() {
    database.DB.Sync2(domain.SyncDomains...)
    database.DB.Sync2(model.SyncModels...)
}