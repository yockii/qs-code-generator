package service

import (
    "errors"
    "time"

    "github.com/yockii/qscore/pkg/database"
    "github.com/yockii/qscore/pkg/domain"
    "github.com/yockii/qscore/pkg/util"

    "{{ .application.Package }}/internal/model"
)

var {{ .table.Name | title }}Service = new({{ .table.Name | untitle }}Service)
type {{ .table.Name | untitle }}Service struct {}

func (s *{{ .table.Name | untitle }}Service) Add(instance *model.{{ .table.Name | title }}) (isDuplicated bool, success bool, err error) {
    {{ range .table.Columns }}
        {{- if (not .Nullable) -}}
            {{ if (eq .Type 1) }}
            if instance.{{ .Name }} == ""
            {{ else if (eq .Type 2) }}
            if instance.{{ .Name }} == 0
            {{ else if (eq .Type 3) }}
            if instance.{{ .Name }}.IsZero()
            {{- end }} {
                return false, false, errors.New("{{ .DisplayName }}不能为空")
            }
        {{- end -}}
    {{ end }}
    var c int64 = 0
    {{ $tableName := .table.Name }}
    {{ range .table.UniqueCheckColumnNames }}
    c, err = database.DB.Count(&model.{{ $tableName | title }}{
        {{ range . -}}
            {{ . | title }}: instance.{{ . | title }},
        {{- end }}
    })
    if err != nil {
        return
    }
    if c > 0 {
        isDuplicated = true
        return
    }
    {{ end }}
    instance.Id = model.{{ .table.Name | title }}IdPrefix + util.GenerateDatabaseID()
    _, err = database.DB.Insert(instance)
    success = err == nil
    return
}

func (s *{{ .table.Name | untitle }}Service) Remove(instance *model.{{ .table.Name | title }}) (bool, error) {
    if instance.Id == "" {
        return false, errors.New("id不能为空")
    }
    c, err := database.DB.Delete(instance)
    if err != nil {
        return false, err
    }
    if c == 0 {
        return false, nil
    }
    return true, nil
}

func (s *{{ .table.Name | untitle }}Service) Update(instance *model.{{ .table.Name | title }}) (bool, error) {
    if instance.Id == "" {
        return false, errors.New("ID不能为空")
    }
    // 不允许更改的字段
    {{ range .table.Columns }}
        {{- if (not .Updatable) -}}
            instance.{{ .Name }} = {{ if (eq .Type 1) }}""{{ else if (eq .Type 2) }}0{{ else }}nil{{ end }}
        {{- end -}}
    {{ end }}
    c, err := database.DB.ID(instance.Id).Update(&model.{{ $tableName | title }}{
        // 允许更改的字段
        {{ range .table.Columns}}
            {{- if .Updatable -}}
               {{ .Name | title }}: instance.{{ .Name | title }},
            {{- end -}}
        {{ end }}
    })
    if err != nil {
        return false, err
    }
    if c == 0 {
        return false, nil
    }
    return true, nil
}

func (s *{{ .table.Name | untitle }}Service) Get(instance *model.{{ .table.Name | title }}) (*model.{{ .table.Name | title }}, error) {
    has, err := database.DB.Get(instance)
    if err != nil {
        return nil, err
    }
    if !has {
        return nil, nil
    }
    return instance, nil
}

func (s *{{ .table.Name | untitle }}Service) Paginate(condition *model.{{ .table.Name | title }}, limit, offset int, orderBy string) (int, []*model.{{ .table.Name | title }}, error) {
    return s.PaginateBetweenTimes(condition, limit, offset, orderBy, nil)
}

func (s *{{ .table.Name | untitle }}Service) PaginateBetweenTimes(condition *model.{{ .table.Name | title }}, limit, offset int, orderBy string, tcList map[string]*domain.TimeCondition) (int, []*model.{{ .table.Name | title }}, error) {
    // 处理不允许查询的字段
    {{ range .table.Columns }}
        {{- if (not .Searchable) -}}
            instance.{{ .Name }} = {{ if (eq .Type 1) }}""{{ else if (eq .Type 2) }}0{{ else }}nil{{ end }}
        {{- end -}}
    {{ end }}

    // 处理sql
    session := database.DB.NewSession()
    if limit > -1 && offset > -1 {
        session.Limit(limit, offset)
    }

    if orderBy != "" {
        session.OrderBy(orderBy)
    }
    {{ if .table.RecordUpdateTime -}}
        session.Desc("update_time")
    {{- end }}
    {{ if .table.RecordCreateTime -}}
        session.Desc("create_time")
    {{- end }}

    // 处理时间字段，在某段时间之间
    for tc, tr := range tcList {
        if tc != "" {
            if !tr.Start.IsZero() && !tr.End.IsZero() {
                session.Where(tc+" between ? and ?", time.Time(tr.Start), time.Time(tr.End))
            } else if tr.Start.IsZero() && !tr.End.IsZero() {
                session.Where(tc+" <= ?", time.Time(tr.End))
            } else if !tr.Start.IsZero() && tr.End.IsZero() {
                session.Where(tc+" > ?", time.Time(tr.Start))
            }
        }
    }

    // 模糊查找
    {{ range .table.Columns }}
        {{- if (eq .Type 1) -}}
            if condition.{{ .Name | title }} != "" {
                session.Where("{{ .Name | snakecase }} like ?", condition.{{ .Name | title}} + "%")
                condition.{{ .Name | title }} = ""
            }
        {{- end -}}
    {{ end }}

    var list []*model.{{ .table.Name | title }}
    total, err := session.FindAndCount(&list, condition)
    if err != nil {
        return 0, nil, err
    }
    return int(total), list, nil
}
