#ifndef CODEEDITOR_H
#define CODEEDITOR_H

#include <QTextEdit>
#include <QCompleter>

class CodeEditor : public QTextEdit
{
    Q_OBJECT

public:
    explicit CodeEditor(QWidget *parent = nullptr);
    void setCompleter(QCompleter *completer);
    QCompleter *completer() const;

protected:
    void keyPressEvent(QKeyEvent *e) override;

private slots:
    void insertCompletion(const QString &completion);

private:
    QString textUnderCursor() const;

    QCompleter *c;
};

#endif // CODEEDITOR_H
