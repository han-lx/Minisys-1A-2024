#include "codeeditor.h"
#include <QAbstractItemView>
#include <QScrollBar>
#include <QKeyEvent>
#include <QTextCursor>

CodeEditor::CodeEditor(QWidget *parent)
    : QTextEdit(parent), c(nullptr) {}

void CodeEditor::setCompleter(QCompleter *completer)
{
    if (c)
        QObject::disconnect(c, nullptr, this, nullptr);

    c = completer;

    if (!c)
        return;

    c->setWidget(this);
    c->setCompletionMode(QCompleter::PopupCompletion);
    c->setCaseSensitivity(Qt::CaseInsensitive);
    QObject::connect(c, QOverload<const QString &>::of(&QCompleter::activated),
                     this, &CodeEditor::insertCompletion);
}

QCompleter *CodeEditor::completer() const
{
    return c;
}

void CodeEditor::insertCompletion(const QString &completion)
{
    if (c->widget() != this)
        return;

    QTextCursor tc = textCursor();
    int extra = completion.length() - c->completionPrefix().length();
    tc.movePosition(QTextCursor::Left, QTextCursor::KeepAnchor, c->completionPrefix().length());
    tc.insertText(completion);
    setTextCursor(tc);
}

QString CodeEditor::textUnderCursor() const
{
    QTextCursor tc = textCursor();
    tc.select(QTextCursor::WordUnderCursor);
    return tc.selectedText();
}

void CodeEditor::keyPressEvent(QKeyEvent *e)
{
    if (c && c->popup()->isVisible()) {
        // 处理补全窗口的特殊键
        switch (e->key()) {
        case Qt::Key_Enter:
        case Qt::Key_Return:
        case Qt::Key_Escape:
        case Qt::Key_Tab:
        case Qt::Key_Backtab:
            e->ignore();
            return; // 让补全器处理这些按键
        default:
            break;
        }
    }

    QTextEdit::keyPressEvent(e);

    if (!c)
        return;

    QString completionPrefix = textUnderCursor();

    if (completionPrefix.isEmpty()) {
        c->popup()->hide();
        return;
    }

    if (completionPrefix != c->completionPrefix()) {
        c->setCompletionPrefix(completionPrefix);
        c->popup()->setCurrentIndex(c->completionModel()->index(0, 0));
    }

    QRect cr = cursorRect();
    cr.setWidth(c->popup()->sizeHintForColumn(0)
                + c->popup()->verticalScrollBar()->sizeHint().width());
    c->complete(cr); // 在光标位置显示补全
}
