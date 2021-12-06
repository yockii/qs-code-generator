package generator

import (
	"bufio"
	"bytes"
	"embed"
	"io"
	"io/fs"
	"io/ioutil"
	"os"
	"path"
	"path/filepath"
	"text/template"

	"github.com/Masterminds/sprig"
	"github.com/codeskyblue/go-sh"
	"github.com/mholt/archiver/v3"
	"github.com/yockii/qscore/pkg/logger"
	"github.com/yockii/qscore/pkg/util"

	"github.com/yockii/qs-code-generator/pkg/domain"
)

//go:embed tmpl
var tmpl embed.FS

var tpls *template.Template

func init() {
	var err error
	tpls, err = template.New("").Funcs(sprig.TxtFuncMap()).ParseFS(tmpl, "tmpl/*.tpl")
	if err != nil {
		logger.Error(err)
	}
}

func GenerateApplicationSource(application *domain.Application) (bs []byte, err error) {
	var tDir string
	tDir, err = ioutil.TempDir("", "qs-code-generation-*")
	if err != nil {
		return
	}
	defer os.RemoveAll(tDir)
	dir := filepath.Join(tDir, application.Package)
	err = os.Mkdir(dir, fs.ModePerm)
	if err != nil {
		return
	}
	err = dealCmdDir(dir, application)
	if err != nil {
		return
	}
	err = dealModels(dir, application)
	if err != nil {
		return
	}
	err = dealServices(dir, application)
	if err != nil {
		return
	}
	err = dealControllers(dir, application)
	if err != nil {
		return
	}
	err = dealInitial(dir, application)
	if err != nil {
		return
	}
	err = dealConfig(dir, application)
	if err != nil {
		return
	}

	// 代码生成完毕
	cmdSession := sh.NewSession()
	cmdSession.SetDir(dir)
	err = cmdSession.Call("go", "mod", "init", application.Package)
	if err != nil {
		return
	}
	err = cmdSession.Call("go", "mod", "tidy")
	if err != nil {
		return
	}
	err = cmdSession.Call("go", "fmt", "./...")
	if err != nil {
		return
	}

	cmdSession.SetEnv("GOARCH", "amd64")
	cmdSession.SetEnv("GOOS", "windows")
	err = cmdSession.Call("go", "build", "-o", application.Package+"_win.exe", "cmd/main.go")
	if err != nil {
		return
	}
	cmdSession.SetEnv("GOOS", "linux")
	err = cmdSession.Call("go", "build", "-o", application.Package+"_linux", "cmd/main.go")
	if err != nil {
		return
	}
	// 代码编译完毕

	// 将可执行文件和配置文件复制到上层目录
	err = cutDiskFile(filepath.Join(dir, application.Package+"_win.exe"), filepath.Join(tDir, application.Package+"_win.exe"))
	if err != nil {
		return
	}
	err = cutDiskFile(filepath.Join(dir, application.Package+"_linux"), filepath.Join(tDir, application.Package+"_linux"))
	if err != nil {
		return
	}
	///////////////////////////////////

	bs, err = compressAndReadBytes([]string{dir, filepath.Join(tDir, application.Package+"_win.exe"), filepath.Join(tDir, application.Package+"_linux")}, filepath.Join(dir, application.Package+".zip"))
	if err != nil {
		return
	}
	return
}

func dealConfig(tmpDir string, application *domain.Application) error {
	cfgDir := filepath.Join(tmpDir, "conf")
	if err := os.MkdirAll(cfgDir, fs.ModePerm); err != nil {
		return err
	}
	if err := copyEmbedFile2Disk(path.Join("tmpl", "prog", "conf", "config.toml"), filepath.Join(cfgDir, "config.toml")); err != nil {
		return err
	}
	return nil
}

func compressAndReadBytes(dirOrFiles []string, pkg string) ([]byte, error) {
	if err := archiver.Archive(dirOrFiles, pkg); err != nil {
		return nil, err
	}
	if f, err := os.Open(pkg); err != nil {
		return nil, err
	} else {
		defer f.Close()
		buf := bytes.NewBuffer(nil)
		if _, err = io.Copy(buf, f); err != nil {
			return nil, err
		}
		return buf.Bytes(), nil
	}
}

func dealInitial(tmpDir string, application *domain.Application) error {
	if err := os.Mkdir(filepath.Join(tmpDir, "internal", "initial"), fs.ModePerm); err != nil {
		return err
	}
	return generateFile(filepath.Join(tmpDir, "internal", "initial", "initial.go"), "initial.go.tpl", map[string]interface{}{"application": application})
}

func dealModels(tmpDir string, application *domain.Application) error {
	modelDir := filepath.Join(tmpDir, "internal", "model")
	if err := os.MkdirAll(modelDir, fs.ModePerm); err != nil {
		return err
	}
	data := map[string]interface{}{"application": application}
	// index.go
	if err := copyEmbedFile2Disk(path.Join("tmpl", "prog", "internal", "model", "Index.go"), filepath.Join(modelDir, "Index.go")); err != nil {
		return err
	}
	// 循环Tables
	for _, table := range application.Tables {
		data["table"] = table
		if err := generateFile(filepath.Join(modelDir, util.CamelString(table.Name)+".go"), "model.go.tpl", data); err != nil {
			return err
		}
	}
	return nil
}

func dealServices(tmpDir string, application *domain.Application) error {
	serviceDir := filepath.Join(tmpDir, "internal", "service")
	if err := os.MkdirAll(serviceDir, fs.ModePerm); err != nil {
		return err
	}
	data := map[string]interface{}{"application": application}
	// 处理固化的几个项目: user/role/resource/dict
	{
		// 复制几个文件到目标文件夹
		tplServiceDir := path.Join("tmpl", "prog", "internal", "service")
		// user
		if err := copyEmbedFile2Disk(path.Join(tplServiceDir, "UserService.go"), filepath.Join(serviceDir, "UserService.go")); err != nil {
			return err
		}
		// role
		if err := copyEmbedFile2Disk(path.Join(tplServiceDir, "RoleService.go"), filepath.Join(serviceDir, "RoleService.go")); err != nil {
			return err
		}
		// resource
		if err := copyEmbedFile2Disk(path.Join(tplServiceDir, "ResourceService.go"), filepath.Join(serviceDir, "ResourceService.go")); err != nil {
			return err
		}
		// dict
		if err := copyEmbedFile2Disk(path.Join(tplServiceDir, "DictService.go"), filepath.Join(serviceDir, "DictService.go")); err != nil {
			return err
		}
	}
	// 循环Tables
	for _, table := range application.Tables {
		data["table"] = table
		if err := generateFile(filepath.Join(serviceDir, util.CamelString(table.Name)+"Service.go"), "service.go.tpl", data); err != nil {
			return err
		}
	}
	return nil
}

func dealControllers(tmpDir string, application *domain.Application) error {
	controllerDir := filepath.Join(tmpDir, "internal", "controller")
	if err := os.MkdirAll(controllerDir, fs.ModePerm); err != nil {
		return err
	}
	data := map[string]interface{}{"application": application}
	// index.go
	if err := generateFile(filepath.Join(controllerDir, "Index.go"), "controller.index.go.tpl", data); err != nil {
		return err
	}
	// 处理固化的几个项目: user/role/resource/controller
	{
		// user
		if err := generateFile(filepath.Join(controllerDir, "UserController.go"), "controller.user.go.tpl", data); err != nil {
			return err
		}
		// role
		if err := generateFile(filepath.Join(controllerDir, "RoleController.go"), "controller.role.go.tpl", data); err != nil {
			return err
		}
		// resource
		if err := generateFile(filepath.Join(controllerDir, "ResourceController.go"), "controller.resource.go.tpl", data); err != nil {
			return err
		}
		// dict
		if err := generateFile(filepath.Join(controllerDir, "DictController.go"), "controller.dict.go.tpl", data); err != nil {
			return err
		}
	}
	// 循环tables进行写入
	for _, table := range application.Tables {
		data["table"] = table
		if err := generateFile(filepath.Join(controllerDir, util.CamelString(table.Name)+"Controller.go"), "controller.go.tpl", data); err != nil {
			return err
		}
	}
	return nil
}

func dealCmdDir(tmpDir string, application *domain.Application) error {
	if err := os.Mkdir(filepath.Join(tmpDir, "cmd"), fs.ModePerm); err != nil {
		return err
	}
	return generateFile(filepath.Join(tmpDir, "cmd", "main.go"), "main.go.tpl", map[string]interface{}{"application": application})
}

func generateFile(filePath, templateName string, data map[string]interface{}) error {
	if file, err := os.OpenFile(filePath, os.O_CREATE|os.O_RDWR, fs.ModePerm); err != nil {
		return err
	} else {
		defer file.Close()
		bufferWriter := bufio.NewWriter(file)
		tpls.ExecuteTemplate(bufferWriter, templateName, data)
		return bufferWriter.Flush()
	}
}

func copyEmbedFile2Disk(embedFile, outFile string) error {
	f, err := tmpl.Open(embedFile)
	if err != nil {
		return err
	}
	defer f.Close()
	bufferReader := bufio.NewReader(f)
	targetFile, err0 := os.OpenFile(outFile, os.O_CREATE|os.O_RDWR, fs.ModePerm)
	if err0 != nil {
		return err0
	}
	defer targetFile.Close()
	bufferWriter := bufio.NewWriter(targetFile)
	_, err = io.Copy(bufferWriter, bufferReader)
	if err != nil {
		return err
	}
	return nil
}

func copyDiskFile(srcFile, outFile string) error {
	f, err := os.Open(srcFile)
	if err != nil {
		return err
	}
	defer f.Close()
	bufferReader := bufio.NewReader(f)
	targetFile, err0 := os.OpenFile(outFile, os.O_CREATE|os.O_RDWR, fs.ModePerm)
	if err0 != nil {
		return err0
	}
	defer targetFile.Close()
	bufferWriter := bufio.NewWriter(targetFile)
	_, err = io.Copy(bufferWriter, bufferReader)
	if err != nil {
		return err
	}
	return nil
}

func cutDiskFile(srcFile, outFile string) error {
	if err := copyDiskFile(srcFile, outFile); err != nil {
		return err
	}
	return os.Remove(srcFile)
}
