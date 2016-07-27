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

#ifndef WINDOWSELECTOR_H
#define WINDOWSELECTOR_H

#include <QDialog>
#include <QList>
#include <QString>
#include <QListWidgetItem>
#include <QVBoxLayout>

namespace Ui {
class WindowSelector;
}

class ScreenShotWidget;

class WindowSelector : public QDialog
{
    Q_OBJECT

public:
    explicit WindowSelector(QWidget *parent = 0);
    ~WindowSelector();

    void init();

    struct Window
    {
        QString name;
        uint64_t psn, winid;
        QPixmap icon;

        bool operator==(const Window& other) const
        {
            return name == other.name && psn == other.psn;
        }
    };
    static QList<Window> getWindowList();

signals:
    void windowSelected(const QString& name, uint64_t psn, uint64_t id, const QPixmap& image);

private slots:
    void emitSelected();
    void itemChanged(const QListWidgetItem* item);

private:
    Ui::WindowSelector *ui;
    ScreenShotWidget* screenShot;
    QVBoxLayout* screenShotLayout;
};

#endif // WINDOWSELECTOR_H
