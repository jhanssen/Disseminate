#include "WindowSelector.h"
#include "WindowSelectorOSX.h"
#include "Item.h"
#include "ui_WindowSelector.h"

static QString toQString(const std::string& str)
{
    return QString::fromUtf8(str.c_str(), str.size());
}

WindowSelector::WindowSelector(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::WindowSelector)
{
    ui->setupUi(this);
    connect(this, &WindowSelector::accepted, this, &WindowSelector::emitSelected);
}

WindowSelector::~WindowSelector()
{
    delete ui;
}

void WindowSelector::init()
{
    std::vector<WindowInfo> infos;
    getWindows(infos);

    ui->windowListWidget->clear();

    QListWidget* list = ui->windowListWidget;
    for (const auto& info : infos) {
        QString str = toQString(info.name) + " (" + QString::number(info.psn) + ")";
        list->addItem(new WindowItem(str, info.psn));
    }
}

void WindowSelector::emitSelected()
{
    const auto& items = ui->windowListWidget->selectedItems();
    if (items.size() == 1) {
        const WindowItem* item = static_cast<WindowItem*>(items.first());
        emit windowSelected(item->text(), item->wid);
    }
}
