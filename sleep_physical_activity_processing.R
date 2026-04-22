# install.packages("GGIR", dependencies = TRUE)
# install.packages("GGIRread")
library(GGIR)
packageVersion("GGIR")
mode = c(1,2,3,4,5) # GGIR管道中的5个部分都将被执行
datadir = "G:/Dataset_2/GLAN/band/data" # GENEActiv .bin数据存放的位置
outputdir = "G:/Dataset_2/GLAN/band/results_1min" # GGIR输出结果存放的位置
studyname ="test" 
f0 = 1 # 起始文件索引，GGIR读取时datadir中文件时，文件按字母顺序排序，对应数字索引为1,2,3，...
f1 = 0 # 终止文件索引，猜测文件索引没有0，故此处设为0，代表GGIR将执行至datadir中最后一个文件。
GGIR(
  #------------------------------
  # General parameters
  #------------------------------
  mode = mode, datadir = datadir, outputdir = outputdir,
  studyname = studyname, 
  f0 = f0,
  f1 = f1,
  idloc=1, # 提取ID名，1代表从文件标题字段中提取ID名，这个不重要
  overwrite = TRUE, # 覆写mode = c(1:5)中的所有输出，不利用可能已存在的milestone数据
  do.imp = TRUE, # 执行缺失值插补，推荐执行
  print.filename = TRUE, # 每次执行时，打印文件名
  storefolderstructure = FALSE, # 不重要
  #------------------------------
  # Part 1 parameters:
  # Loads the data, works on **data quality**, and stores derived summary measures per time interval, also known as signal features (referred to as metrics), as needed for the following parts.
  #------------------------------
  windowsizes = c(5,900,3600), # 5秒是GGIR中默认的epoch level，用于将不同采样率的数据统一聚合为5秒，是加速度（enmo）和方位角（anglez）的计算基础；900和3600秒时间窗口是服务于non-wear检测，使用默认值15分钟和1一小时。
  do.cal = TRUE, # 执行自动校准，这很重要
  do.enmo = TRUE, # 衡量physical activity强度的主要指标
  do.anglez = TRUE, # 进行姿态检测的主要指标
  chunksize = 1, # GGIR执行分块处理，避免资源溢出，1代表校准时块大小为12小时；指标计算时块大小为24小时
  printsummary = TRUE, # 在控制台打印校准过程的摘要，不重要
  #------------------------------
  # Part 2 parameters: 
  # Basic data quality assessment based on the extract metrics and description of the data per day, per file, and optionally per day segment.
  #------------------------------
  data_masking_strategy = 1, #数据掩膜策略，1代表根据hrs.del.start和hrs.del.end截取数据
  ndayswindow = 7, # 当且仅当数据掩膜策略为3和5时启动，这里不影响
  hrs.del.start = 1, # 1代表从数据记录开始后1小时开始截取
  hrs.del.end = 1, # 1代表从数据记录截止前1小时完成截取
  maxdur = 9, # 实验设计为几天？9代表9天，0代表未知，这里使用9，影响应该不大
  includedaycrit = 16, # 特定分析中要求的一天内最小有效小时数，16小时是默认值
  qwindow = c(0, 24), # 指定变量计算窗口，这里便是,0-24共计1个窗口进行变量计算
  M5L5res = 10, # 分析M5，L5的时间分辨率，单位为分钟。L5表示找出一天内活动量最低的连续5小时窗口，M5表示找出一天内活动量最高的连续5小时窗口
  winhr = c(5), # M5L5分析中时间窗口的大小，单位为小时。
  # qlevels = c(c(1380/1440),c(1410/1440)), # 百分位统计，暂时用不上
  # ilevels = c(seq(0,400,by=50),8000), # 手动间距统计，暂时用不上
  mvpathreshold = c(100), # 参考文献Hildebrand 2016，默认值100是合理的，用于划分MVPA和非MVPA
  #------------------------------
  # Part 3 parameters: 
  # Estimation rest periods, needed for input to Part 4.
  #------------------------------
  anglethreshold = 5, # 使用vanHees2015算法检测SIB时适用，表示寻找z角度变化幅度小于5度的时段
  timethreshold = c(5), # 使用vanHees2015算法检测SIB时适用，表示z角度变化幅度小于5度的时段的最小持续时间为5分钟，才可被认为为SIB
  ignorenonwear = TRUE, # 忽略non-wear时段对于SIB检测的贡献
  #------------------------------
  # Part 4 parameters: 
  # Labels the rest periods derived in Part 3 as sleep per night and per file.
  #------------------------------
  excludefirstlast = FALSE, # 不忽略第一个和最后一个夜晚
  includenightcrit = 16, # 睡眠分析中每晚所需最少有效小时数（noon to noon）,注意与includedaycrit的区别
  def.noc.sleep = 1, # 使用算法自动检测睡眠时间窗口（sleep period time window, SPT）
  HASPT.algo = "HDCZA", # 默认算法
  HDCZA_threshold = 0.2, # 默认阈值
  # loglocation = "D:/sleeplog.csv", # 这里不使用睡眠日志
  outliers.only = FALSE, # do.visual = TRUE时使用，FALSE代表所有夜晚都将被可视化
  # criterror = 4, # outliers.only = TRUE时使用，这里用不上
  relyonguider = FALSE, # 除非参与者被告知清醒时不佩戴手环，其他情况下都设置为FALSE
  # colid = 1, # 使用睡眠日志时才启用
  coln1 = 2,# 使用睡眠日志时才启用
  do.visual = TRUE,
  #------------------------------7
  # Part 5 parameters: 
  # Compiles time series with classification of sleep and physical behaviour categories by re-using information derived in part 2, 3, and 4. This includes the detection of behavioural bouts, which are time segments where the same behaviour is sustained for duration as specified by the user. Next, Part 5 generates a descriptive summary such as time spent in and average acceleration per behavioural category, but also behavioural fragmentation.
  #------------------------------
  # Key functions: Merging physical activity with sleep analyses 
  threshold.lig = c(40), # 参考文献Hildebrand 2016，默认值40是合理的，用于确定inactivity to light physical activity
  threshold.mod = c(100), # 参考文献Hildebrand 2016，默认值100是合理的，用于确定light to moderate physical activity
  threshold.vig = c(400), # 参考文献Hildebrand 2016，默认值400是合理的，用于确定moderate to vigorous physical activity
  boutcriter = 0.8, # 用于part 2，一个时间段超过80%为mvpa才能算作是mvpa
  boutcriter.in = 0.9, # 用于part 5，一个时间段超过90%（默认值）为inactivity才能算作inactivity
  boutcriter.lig = 0.8, # 用于part 5，一个时间段超过80%（默认值）为light activity才能算作light activity
  boutcriter.mvpa = 0.8, # 用于part 5，一个时间段超过80%（默认值）为moderate/vigorous activity才能算作moderate/vigorous activity
  mvpadur = c(1, 5, 10), # 用于part 2, 检测mvpa行为的时间段（bout）,c(1, 5, 10)分钟为默认值
  boutdur.in = c(10,20,30), # 用于part 5, 检测inactivity行为的时间段（bout）, c(10,20,30)分钟为默认值，从大至小依次检验
  boutdur.lig = c(1,5,10), # 用于part 5, 检测light activity行为的时间段（bout）, c(1,5,10)分钟为默认值，从大至小依次检验
  boutdur.mvpa = c(1,5,10), # 用于part 5, 检测light activity行为的时间段（bout）, c(1,5,10)分钟为默认值，从大至小依次检验
  timewindow = c("MM"), # part 5统计总结所用时间窗口，MM表示midnight to midnight
  part5_agg2_60seconds = TRUE, # 不聚合分析的基础epoch level,仍然使用part 2中5s
  frag.metrics = NULL, # 不计算行为碎片度
  save_ms5rawlevels = TRUE, # 导出时间序列
  save_ms5raw_format = "csv", # 导出时间序列格式为csv
  save_ms5raw_without_invalid = TRUE, # 移除无效天
  acc.metric = "ENMO", # part 5分析的指标
  #----------------------------------
  # Report generation 
  #------------------------------
  do.report = c(1,2,3,4,5)
)