#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QTextEdit>
#include <QAction>
#include <QMenu>
#include <QFileDialog>
#include <QTextStream>
#include <QMessageBox>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void openFile();   // 打开文件
    void saveFile();   // 保存文件
    void compileCode();
    void runCode();

private:
    Ui::MainWindow *ui;
    QTextEdit *textEdit;  // 用于显示和编辑代码的文本框
    QTextEdit *outputTextEdit;  // 用于显示编译和运行输出的文本框
    QString currentFilePath;  // 当前文件路径
};

#endif // MAINWINDOW_H
