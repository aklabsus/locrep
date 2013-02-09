del *.zip

copy /y htm.diz file_id.diz
pkzip25 -add -rec -dir akdtphtm.zip *.html *.pas *.cmd file_id.diz akdtopic.bat

copy /y chm.diz file_id.diz
pkzip25 -add -rec -dir akdtpchm.zip *.chm *.pas *.cmd file_id.diz
del file_id.diz

copy /y *.zip downloads\aktools 