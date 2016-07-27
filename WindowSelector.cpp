#include "WindowSelector.h"
#include "WindowSelectorOSX.h"
#include "Item.h"
#include "Helpers.h"
#include "ui_WindowSelector.h"

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
        const QString str = helpers::toQString(info.name) + " (" + QString::number(info.psn) + ")";
        list->addItem(new WindowItem(str, helpers::toQString(info.name), info.psn));
    }
}

void WindowSelector::emitSelected()
{
    const auto& items = ui->windowListWidget->selectedItems();
    if (items.size() == 1) {
        const WindowItem* item = static_cast<WindowItem*>(items.first());
        emit windowSelected(item->wname, item->wid);
    }
}

QList<WindowSelector::Window> WindowSelector::getWindowList()
{
    std::vector<WindowInfo> infos;
    getWindows(infos);

    QList<Window> ret;
    for (const auto& info : infos) {
        const Window win = { helpers::toQString(info.name), info.psn };
        ret.append(win);
    }

    return ret;
}
