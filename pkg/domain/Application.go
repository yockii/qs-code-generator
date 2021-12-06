package domain

type Application struct {
	Package string
	Tables  []*Table
}

type Table struct {
	Name                   string
	RecordCreateTime       bool
	RecordUpdateTime       bool
	RecordDeleteTime       bool
	Columns                []*Column
	UniqueCheckColumnNames [][]string
}

type Column struct {
	Name        string
	DisplayName string
	Type        int // 1-string(默认) 2-int 3-DateTime
	Comment     string
	ColumnType  string
	Nullable    bool
	Updatable   bool
	Searchable  bool
}
