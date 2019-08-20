#!  /usr/bin/python

import json
import xml.etree.ElementTree as ET
import datetime


epgfile = open('/dev/stdin','r').read()

epgdata = json.loads(epgfile)

tv=ET.Element('tv')
tv.attrib = {'generator-info-name': 'json2xml'}

for channeltext in epgdata['channels'] :
    channel = ET.SubElement(tv, 'channel')
    channel.attrib = {'id': channeltext}
    displayname = ET.SubElement(channel,'display-name')
    displayname.attrib = {'lang':'cs'}
    displayname.text = channeltext


for channel in epgdata['channels'] :
     for event in epgdata['channels'][channel]:
         programme = ET.SubElement(tv,'programme')
         
         l_start = datetime.datetime.strptime(event['startTime'], "%Y-%m-%d %H:%M")
         l_stop = datetime.datetime.strptime(event['endTime'], "%Y-%m-%d %H:%M")
         
         programme.attrib = { 'start': l_start.strftime("%Y%m%d%H%M%S +0200"), 'stop': l_stop.strftime("%Y%m%d%H%M%S +0200"), 'channel': channel  }
         
         title = ET.SubElement(programme, 'title')
         title.text = event['title']
         title.attrib = {'lang': 'cs'} 
         
        
         desc = ET.SubElement(programme, 'desc')
         desc.text = event['description']
         desc.attrib = {'lang': 'cs'} 
         
         date = ET.SubElement(programme, 'date')
         date.text = l_start.strftime("%Y%m%d")

ET.dump(tv)

