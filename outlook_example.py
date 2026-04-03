# coding: utf-8

import sys
from datetime import datetime
import win32com.client

outlook = win32com.client.Dispatch('Outlook.Application')
mail = outlook.CreateItem(0)

# 週報を添付. 絶対パスで指定.
args = sys.argv
path = args[1]
mail.Attachments.Add (path)

mail.BodyFormat = 1 #1:Text, 2:HTML, 3:RichText
mail.To = 'example@example.com'
mail.Cc = 'me@example.com'

# 週番号を取得
# その年の最初の木曜日がある日が1週目になるらしい.
# したがって金曜日-水曜日までの間に書けば正しい週になる.
today = datetime.now().isocalendar()
week_num = today[1]

mail.Subject = f'週報第{week_num}週（name）'
body = '''xxさん、

今週の週報です。よろしくお願いします。

'''
sign = '''ril'''
mail.Body = body + sign

# 出来上がったメール確認
mail.Display(False) #Trueだとoutlookがロックされる？
# 確認せず送信する場合は、mail.Display(True)を消して、以下
# mail.Send()
