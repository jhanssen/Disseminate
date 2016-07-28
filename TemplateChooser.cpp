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

#include "TemplateChooser.h"
#include "Helpers.h"
#include "Utils.h"
#include "WindowSelectorOSX.h"
#include "ui_TemplateChooser.h"

TemplateChooser::TemplateChooser(QWidget *parent, const QString& current, const QStringList& temps, uint64_t psn, uint64_t windowId) :
    QDialog(parent),
    ui(new Ui::TemplateChooser),
    wpsn(psn), wid(windowId)
{
    ui->setupUi(this);
    ui->templateList->addItem("<No template>");
    if (current.isEmpty())
        ui->templateList->setCurrentItem(ui->templateList->item(0));
    for (const auto& t : temps) {
        QListWidgetItem* item = new QListWidgetItem(t);
        ui->templateList->addItem(item);
        if (t == current)
            ui->templateList->setCurrentItem(item);
    }

    connect(this, &TemplateChooser::accepted, this, &TemplateChooser::emitChosen);

    screenShot = new helpers::ScreenShotWidget(ui->widget);
    // this function should probably live in a different file
    screenShot->setPixmap(getScreenshot(wid));
    screenShotLayout = new QVBoxLayout(ui->widget);
    screenShotLayout->addWidget(screenShot);
    screenShot->show();
}

TemplateChooser::~TemplateChooser()
{
    delete ui;
}

void TemplateChooser::emitChosen()
{
    if (!ui->templateList->currentItem())
        return;
    emit chosen(wpsn, ui->templateList->currentItem()->text());
}
