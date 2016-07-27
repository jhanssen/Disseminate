/*
  Disseminate, keyboard broadcaster
  Copyright (C) 2016  Jan Erik Hanssen

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "WindowSelector.h"
#include "WindowSelectorOSX.h"
#include "Item.h"
#include "Helpers.h"
#include "ui_WindowSelector.h"
#include <QPainter>

class ScreenShotWidget : public QWidget
{
public:
    ScreenShotWidget(QWidget* p)
        : QWidget(p)
    {
        setMinimumSize(100, 100);
        setSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::MinimumExpanding);
    }

    void setPixmap(const QPixmap& pm)
    {
        pixmap = pm;
    }

protected:
    void paintEvent(QPaintEvent*)
    {
        QPainter painter(this);
        if (!pixmap.isNull()) {
            QRect wr = rect();
            const double fracx = static_cast<double>(wr.width()) / pixmap.width();
            const double fracy = static_cast<double>(wr.height()) / pixmap.height();
            if (fracx < fracy) {
                // ratio for width
                wr.setHeight(pixmap.height() * fracx);
            } else {
                // ratio for height
                wr.setWidth(pixmap.width() * fracy);
            }
            painter.drawPixmap(wr, pixmap);
        }
    }

private:
    QPixmap pixmap;
};

WindowSelector::WindowSelector(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::WindowSelector)
{
    ui->setupUi(this);
    connect(this, &WindowSelector::accepted, this, &WindowSelector::emitSelected);
    connect(ui->windowListWidget, &QListWidget::currentItemChanged, this, &WindowSelector::itemChanged);

    screenShot = new ScreenShotWidget(ui->imageWidget);
    screenShotLayout = new QVBoxLayout(ui->imageWidget);
    screenShotLayout->addWidget(screenShot);
    screenShot->show();
}

WindowSelector::~WindowSelector()
{
    delete screenShot;
    delete screenShotLayout;
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
        list->addItem(new WindowItem(str, helpers::toQString(info.name), info.psn, info.windowId, info.image));
    }
}

void WindowSelector::emitSelected()
{
    const auto& items = ui->windowListWidget->selectedItems();
    if (items.size() == 1) {
        const WindowItem* item = static_cast<WindowItem*>(items.first());
        emit windowSelected(item->wname, item->wpsn, item->wid, item->wicon);
    }
}

QList<WindowSelector::Window> WindowSelector::getWindowList()
{
    std::vector<WindowInfo> infos;
    getWindows(infos);

    QList<Window> ret;
    for (const auto& info : infos) {
        const Window win = { helpers::toQString(info.name), info.psn, info.windowId, info.image };
        ret.append(win);
    }

    return ret;
}

void WindowSelector::itemChanged(const QListWidgetItem* item)
{
    if (!item) {
        screenShot->setPixmap(QPixmap());
    } else {
        const WindowItem* witem = static_cast<const WindowItem*>(item);
        const QPixmap shot = getScreenshot(witem->wid);
        screenShot->setPixmap(shot);
        screenShot->update();
    }
}
