#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QTextEdit>
#include <QFileDialog>
#include <QTextStream>
#include "codehighlighter.h"
#include <QProcess>
#include <QVBoxLayout>
#include <QTemporaryFile>
#include <QLabel>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent), ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    // 设置窗口标题
    setWindowTitle(tr("IDE"));

    // 设置整个窗口背景颜色为深色
    QPalette windowPalette;
    windowPalette.setColor(QPalette::Window, QColor(30, 30, 30));  // 深色背景
    setPalette(windowPalette);

    // 初始化文本编辑器
    textEdit = new QTextEdit(this);
    setCentralWidget(textEdit);
    textEdit->setStyleSheet("background-color: #2E2E2E; color: white;");

    // 创建输出文本编辑器（用于显示编译、运行输出）
    outputTextEdit = new QTextEdit(this);
    outputTextEdit->setReadOnly(true);  // 输出区域不可编辑
    outputTextEdit->setMinimumHeight(100); // 设置输出区域的最小高度
    outputTextEdit->setMaximumHeight(200); // 设置输出区域的最小高度
    outputTextEdit->setStyleSheet("background-color: #2E2E2E; color: white;");

    // 创建垂直布局管理器
    QVBoxLayout *layout = new QVBoxLayout;

    // 将文本编辑控件添加到布局中
    layout->addWidget(textEdit);
    layout->addWidget(outputTextEdit);

    // 创建一个中央部件，设置其布局
    QWidget *centralWidget = new QWidget(this);
    centralWidget->setLayout(layout);
    setCentralWidget(centralWidget);

    // 创建一个字体，设置字体大小
    QFont font = textEdit->font();
    font.setPointSize(14);
    textEdit->setFont(font);

    // 应用语法高亮
    CodeHighlighter *highlighter = new CodeHighlighter(textEdit->document());

    // 创建菜单栏
    QMenu *fileMenu = menuBar()->addMenu(tr("&File"));
    QMenu *buildMenu = menuBar()->addMenu(tr("&Build"));

    QAction *openAction = new QAction(tr("&Open"), this);
    openAction->setShortcut(QKeySequence::Open);  // 设置快捷键 Ctrl+O
    fileMenu->addAction(openAction);
    connect(openAction, &QAction::triggered, this, &MainWindow::openFile);

    QAction *saveAction = new QAction(tr("&Save"), this);
    saveAction->setShortcut(QKeySequence::Save);  // 设置快捷键 Ctrl+S
    fileMenu->addAction(saveAction);
    connect(saveAction, &QAction::triggered, this, &MainWindow::saveFile);

    QAction *compileAction = new QAction(tr("&Compile"), this);
    compileAction->setShortcut(Qt::Key_F5);  // 设置快捷键 F5
    buildMenu->addAction(compileAction);
    connect(compileAction, &QAction::triggered, this, &MainWindow::compileCode);

    QAction *runAction = new QAction(tr("&Run"), this);
    runAction->setShortcut(QKeySequence(Qt::CTRL + Qt::Key_F5));  // 设置快捷键 Ctrl+F5
    buildMenu->addAction(runAction);
    connect(runAction, &QAction::triggered, this, &MainWindow::runCode);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::openFile()
{
    // 弹出文件选择对话框
    QString fileName = QFileDialog::getOpenFileName(this, tr("Open File"), "", tr("C++ Files (*.c)"));

    if (!fileName.isEmpty()) {
        QFile file(fileName);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QTextStream in(&file);
            textEdit->setPlainText(in.readAll());
            file.close();
            currentFilePath = fileName;  // 记录文件路径
        } else {
            QMessageBox::warning(this, tr("Error"), tr("Unable to open file"));
        }
    }
}

void MainWindow::saveFile()
{
    // 如果当前文件已经有路径，直接保存
    if (!currentFilePath.isEmpty()) {
        QFile file(currentFilePath);
        if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
            QTextStream out(&file);
            out << textEdit->toPlainText();
            file.close();
        } else {
            QMessageBox::warning(this, tr("Error"), tr("Unable to save file"));
        }
    } else {
        // 如果没有文件路径，弹出保存对话框
        QString fileName = QFileDialog::getSaveFileName(this, tr("Save File"), "", tr("C++ Files (*.c)"));
        if (!fileName.isEmpty()) {
            QFile file(fileName);
            if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
                QTextStream out(&file);
                out << textEdit->toPlainText();
                file.close();
                currentFilePath = fileName;  // 记录文件路径
            } else {
                QMessageBox::warning(this, tr("Error"), tr("Unable to save file"));
            }
        }
    }
}


void MainWindow::compileCode()
{
    QString code = textEdit->toPlainText(); // 获取文本编辑器中的代码
    if (code.isEmpty()) {
        QMessageBox::warning(this, tr("Error"), tr("No code to compile."));
        return;
    }

    // 设置自定义的临时目录路径
    QString tempDir = "E:/IDE";  // 存储临时文件的目录
    if (!QDir(tempDir).exists()) {
        // 如果目录不存在，尝试创建它
        if (!QDir().mkpath(tempDir)) {
            QMessageBox::warning(this, tr("Error"), tr("Failed to create directory: ") + tempDir);
            return;
        }
    }

    QString tempFileName = tempDir + "/test.c";

    QFile tempFile(tempFileName);
    if (!tempFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QMessageBox::warning(this, tr("Error"), tr("Failed to create temporary file."));
        return;
    }

    QTextStream out(&tempFile);
    out << code;
    tempFile.close();

    QString fileName = tempFile.fileName();  // 获取临时文件的路径
    outputTextEdit->clear();
    outputTextEdit->append("Compiling file: " + fileName);

    // 设置 Python 脚本路径
    QString pythonScript = "E:/Minisys-1A-2024-compiler/main.py";  // Python 编译器的路径
    QStringList arguments;
    arguments << fileName;  // 将 C 文件路径传递给 Python 编译器

    // 调用 Python 编译器脚本
    QProcess process;
    process.setProgram("python");
    process.setArguments(QStringList() << pythonScript << fileName);  // 添加文件路径参数
    process.start();
    process.waitForFinished();  // 等待编译完成

    // 读取标准输出和标准错误
    QString output = process.readAllStandardOutput();
    QString error = process.readAllStandardError();

    // 显示编译结果
    outputTextEdit->append("Compilation Output:\n" + output);
    outputTextEdit->append("Compilation Errors:\n" + error);

    if (!error.isEmpty()) {
        QMessageBox::warning(this, tr("Compile Error"), error);
    } else {
        QMessageBox::information(this, tr("Compile Success"), tr("Compilation Successful"));
    }
}

void MainWindow::runCode()
{
    QString code = textEdit->toPlainText(); // 获取文本编辑器中的代码
    if (code.isEmpty()) {
        QMessageBox::warning(this, tr("Error"), tr("No code to run."));
        return;
    }

    // 获取系统的临时目录
    QString customDir = "E:/IDE";  // 临时文件存储目录
    QString tempFileName = customDir + "/test.c";  // 临时文件路径

    // 创建并写入临时文件
    QFile tempFile(tempFileName);
    if (!tempFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QMessageBox::warning(this, tr("Error"), tr("Failed to create temporary file."));
        return;
    }

    QTextStream out(&tempFile);
    out << code;  // 将代码写入临时文件
    tempFile.close();

    // 输出文本框清空并显示编译信息
    outputTextEdit->clear();
    outputTextEdit->append("Compiling and running file: " + tempFileName);

    // 设置 Python 编译器的路径
    QString pythonScript = "/path/to/your/compiler.py";  // Python 编译器路径
    QStringList arguments;
    arguments << tempFileName;  // 将临时文件路径传递给 Python 编译器

    // 调用 Python 编译器脚本进行编译
    QProcess compileProcess;
    compileProcess.setProgram("python3");
    compileProcess.setArguments(QStringList() << pythonScript << tempFileName);  // 添加文件路径参数
    compileProcess.start();
    compileProcess.waitForFinished();  // 等待编译完成

    // 获取编译过程中的标准输出和标准错误
    QString compileOutput = compileProcess.readAllStandardOutput();
    QString compileError = compileProcess.readAllStandardError();

    // 显示编译输出和错误
    outputTextEdit->append("Compilation Output:\n" + compileOutput);
    outputTextEdit->append("Compilation Errors:\n" + compileError);

    if (!compileError.isEmpty()) {
        QMessageBox::warning(this, tr("Compile Error"), compileError);
        return;
    }

    QString executableFile = customDir + "/build/Desktop_Qt_6_8_0_MinGW_64_bit-Debug/test_py.asm";  // 可执行文件路径

    // 检查可执行文件是否存在
    QFileInfo fileInfo(executableFile);
    if (!fileInfo.exists()) {
        QMessageBox::warning(this, tr("Error"), tr("Executable file not found: ") + executableFile);
        return;
    }

    // 运行生成的可执行文件
    QProcess runProcess;
    runProcess.start(executableFile);  // 运行可执行文件
    runProcess.waitForFinished();  // 等待运行完成

    // 获取运行结果输出
    QString runOutput = runProcess.readAllStandardOutput();
    QString runError = runProcess.readAllStandardError();

    // 显示运行结果
    outputTextEdit->clear();
    outputTextEdit->append("Execution Output:\n" + runOutput);
    outputTextEdit->append("Execution Errors:\n" + runError);

    if (!runError.isEmpty()) {
        QMessageBox::warning(this, tr("Execution Error"), runError);
    } else {
        QMessageBox::information(this, tr("Execution Success"), tr("Execution Successful"));
    }
}
