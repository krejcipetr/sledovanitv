#!  /usr/bin/python

import json
import xml.etree.ElementTree as ET
import datetime
import os,time
import requests
import sys

tv=ET.Element('tv')
tv.attrib = {'generator-info-name': 'SledovaniTV-EPG'}

local = time.strftime("%z")

starttime = datetime.datetime.now()
endtime = starttime + datetime.timedelta(days=4)

currenttime = starttime

sledovaniid = os.environ.get('SLEDOVANITVID', '')

while currenttime < endtime :

    #Nacteni dat z api
    r = requests.get(
        f'https://sledovanitv.cz/api/epg?PHPSESSID={sledovaniid}&detail=1&duration=1439&time={currenttime.strftime("%Y-%m-%d%20%H:%M:%S")}'
    )
    epgdata = r.json()
    
    if epgdata['status'] == 0 :
        sys.stderr.write(f"Chyba: Neprobehlo nacteni EPG dat pro cas {currenttime.strftime('%Y-%m-%d %H:%M:%S')}\n")
        sys.exit(1)

    #V pripade nazvy channelu pouze z prvniho bloku
    if currenttime == starttime:
        for channeltext in epgdata['channels'] :
            channel = ET.SubElement(tv, 'channel')
            channel.attrib = {'id': channeltext}
            displayname = ET.SubElement(channel,'display-name')
            displayname.attrib = {'lang':'cs'}
            displayname.text = channeltext

    # Davky z bloku
    for channel in epgdata['channels'] :
         for event in epgdata['channels'][channel]:
             l_stop = datetime.datetime.strptime(event['endTime'], "%Y-%m-%d %H:%M")

             programme = ET.SubElement(tv, 'programme')

             l_start = datetime.datetime.strptime(event['startTime'], "%Y-%m-%d %H:%M")

             programme.attrib = { 'start': l_start.strftime("%Y%m%d%H%M%S ")+local, 'stop': l_stop.strftime("%Y%m%d%H%M%S ")+local, 'channel': channel  }

             title = ET.SubElement(programme, 'title')
             title.text = event['title']
             title.attrib = {'lang': 'cs'}


             desc = ET.SubElement(programme, 'desc')
             desc.text = event['description']
             desc.attrib = {'lang': 'cs'}

             if 'year' in event :
                date = ET.SubElement(programme, 'date')
                date.text = str(event['year']) + '0101'
                date.attrib = {'lang': 'cs'}

    currenttime = currenttime + 1440

ET.dump(tv)

