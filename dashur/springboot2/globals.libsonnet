{
    "parquet-processor" :{
        jar : "processor-transaction-parquet",
        javaOpts: "-Djava.net.preferIPv4Stack=true -XX:+UseG1GC -XX:+UseStringDeduplication",
        limitCpu: "2000" ,
        image :"app-processor-transaction-parquet",
        config: "/conf/dashur-2.config.yaml,/conf/dashur.processor-transaction-parquet.config.yaml"
    }
}

