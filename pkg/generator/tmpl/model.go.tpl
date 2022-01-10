package model

import (
    "github.com/yockii/qscore/pkg/domain"
)

const {{ .table.Name | title }}IdPrefix = "{{ .table.Name | lower }}"

type {{ .table.Name | title }} struct {
    Id string `json:"id,omitempty" xorm:"pk varchar(50)"`
    {{ range .table.Columns -}}
        {{- .Name | title }} {{if (eq .Type 2) }}int{{else if (eq .Type 3)}}domain.DateTime{{else}}string{{end}} `json:"{{ .Name | untitle }},omitempty" xorm:"comment('{{.Comment}}') {{.ColumnType}}"`
    {{- end }}
    {{ if .table.RecordCreateTime -}}
    CreateTime domain.DateTime `json:"createTime" xorm:"created"`
    {{- end }}
    {{ if .table.RecordUpdateTime -}}
    UpdateTime domain.DateTime `json:"updateTime" xorm:"updated"`
    {{- end }}
    {{ if .table.RecordDeleteTime -}}
    DeleteTime domain.DateTime `json:"deleteTime" xorm:"deleted"`
    {{- end }}
}

func init() {
    SyncModels = append(SyncModels, {{ .table.Name | title }}{})
}

type {{ .table.Name | title }}Request struct {
    *{{ .table.Name | title }}
    {{ range .table.Columns -}}
        {{- if (eq .Type 3) -}}
            {{ .Name | title }}Range *domain.TimeCondition `json:"{{ .Name | untitle }}Range,omitempty" query:"{{ .Name | untitle }}Range"`
        {{- end -}}
    {{- end }}
    {{ if .table.RecordCreateTime -}}
    CreateTimeRange *domain.TimeCondition `json:"createTimeRange,omitempty" query:"createTimeRange"`
    {{- end }}
    {{ if .table.RecordUpdateTime -}}
    UpdateTimeRange *domain.TimeCondition `json:"updateTimeRange,omitempty" query:"updateTimeRange"`
    {{- end }}
}