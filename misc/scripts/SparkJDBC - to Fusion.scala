// get the max ID from the db to use for partitioning
val getMaxId = sqlContext.jdbc("jdbc:postgresql://taxi-data-derek.cikmdrscwqru.us-east-1.rds.amazonaws.com:5432/nyc-taxi-data?user=taxidatalogin&password=SuperSecret", "(select max(id) as maxId from trips) tmp")

// note: lower & upper bounds are not filters
val dbOpts = Map(
"url" -> "jdbc:postgresql://taxi-data-derek.cikmdrscwqru.us-east-1.rds.amazonaws.com:5432/nyc-taxi-data?user=taxidatalogin&password=SuperSecret",
"dbtable" -> "trips",
"partitionColumn" -> "id",
"numPartitions" -> "200",
"lowerBound" -> "0",
"upperBound" -> getMaxId.select("maxId").collect()(0)(0).toString,
"fetchSize" -> "5000"
)

var jdbcDF = sqlContext.read.format("jdbc").options(dbOpts).load
jdbcDF.write.format("lucidworks.fusion.index").options(Map("zkhost" -> "10.41.1.80:9983,10.41.1.105:9983,10.41.1.226:9983", "pipeline" -> "nyc-taxi-default", "collection" -> "nyc-taxi")).save
