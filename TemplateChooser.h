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

#ifndef TEMPLATECHOOSER_H
#define TEMPLATECHOOSER_H

#include <QDialog>
#include <QStringList>

namespace Ui {
class TemplateChooser;
}

namespace helpers {
class ScreenShotWidget;
}

class QVBoxLayout;

class TemplateChooser : public QDialog
{
    Q_OBJECT

public:
    explicit TemplateChooser(QWidget *parent, const QString& current, const QStringList& temps, uint64_t psn, uint64_t windowId);
    ~TemplateChooser();

signals:
    void chosen(uint64_t psn, const QString& templ);

private slots:
    void emitChosen();

private:
    Ui::TemplateChooser *ui;
    helpers::ScreenShotWidget* screenShot;
    QVBoxLayout* screenShotLayout;
    uint64_t wpsn, wid;
};

#endif // TEMPLATECHOOSER_H
