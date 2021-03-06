#' ip2long
#' Transforma una IP "192.168.0.1" a integer 3232235521
#' 
#' @param ip 
#' @return
#' @export
#' @examples
#' ip <- ip2long("192.168.0.1")
ip2long <- function(ip) {
    # transforma a vector de characters
    ips <- unlist(strsplit(ip, '.', fixed = TRUE))
    # set up a function to bit-shift, then "OR" the octets
    octet <- function(x,y) bitops::bitOr(bitops::bitShiftL(x, 8), y)
    # Reduce applys a function cumulatively left to right
    return(Reduce(octet, as.integer(ips)))
}

#' long2ip Convert integer IP address 3232235521 to character "192.168.0.1"
#'
#' @param longip 
#' @return
#' @export
#' @examples
long2ip <- function(longip) {
    # set up reversing bit manipulation
    octet <- function(nbits) bitops::bitAnd(bitops::bitShiftR(longip, nbits), 0xFF)
    # Map applys a function to each element of the argument
    return(paste(Map(octet, c(24,16,8,0)), sep = "", collapse = "."))
}

#' ip_in_CIDR
#' Check if IP address (string) is in a CIDR range (string)
#'
#' @param ip 
#' @param cidr 
#' @return
#' @export
#' @examples
ip_in_CIDR <- function(ip, cidr) {
    long.ip <- ip2long(ip)
    cidr.parts <- unlist(strsplit(cidr, "/"))
    cidr.range <- ip2long(cidr.parts[1])
    cidr.mask <- bitops::bitShiftL(bitops::bitFlip(0), (32 - as.integer(cidr.parts[2])))
    return(bitops::bitAnd(long.ip, cidr.mask) == bitops::bitAnd(cidr.range, cidr.mask))
}

#' whatismyip
#'
#' @return
#' @export
#'
#' @examples
whatismyip <- function() {
    return(
      rjson::fromJSON(
        readLines("http://api.hostip.info/get_json.php", warn = F))$ip
    )
}

#' hasIPformat
#'
#' @param ip 
#'
#' @return
#' @export
#'
#' @examples
hasIPformat <- function(ip) {
    b <- as.logical(length(grep("^\\d{1,3}.\\d{1,3}.\\d{1,3}.\\d{1,3}$", x = ip)))
    if (b == TRUE) 
    {
        k <- unlist(strsplit(ip,".", fixed = TRUE))
        b <- all(sapply(k, function(x) as.integer(x) < 256) == TRUE)
    }
    return(as.logical(b))
}

#' getIPaddress
#'
#' @param hostname 
#'
#' @return
#' @export
#'
#' @examples
getIPaddress <- function(hostname) {
    results <- sapply(hostname, function(x) system(paste("nslookup",x), intern = T))
    if (length(results) == 6)
    {
        ip <- stringr::str_extract(results[6,], stringr::perl("\\d{1,3}.\\d{1,3}.\\d{1,3}.\\d{1,3}"))  
    }
    else{
        if (length(results) > 6)
        {
            ip <- stringr::str_extract(results[6:(length(results) - 1),], stringr::perl("\\d{1,3}.\\d{1,3}.\\d{1,3}.\\d{1,3}"))  
        }
        else ip <- "NA"
    }
    return(as.character(ip))
}

#' freegeoip
#' Locate IP address using freegeoip.net service
#' 
#' @param ip 
#' @param format 
#'
#' @return
#' @export
#'
#' @examples
freegeoip <- function(ip, format = ifelse(length(ip) == 1,'list','dataframe')) {
    if (1 == length(ip))
    {
        # a single IP address
        url <- paste(c("http://freegeoip.net/json/", ip), collapse = '')
        ret <- rjson::fromJSON(readLines(url, warn = F))
        if (format == 'dataframe')
            ret <- data.frame(t(unlist(ret)))
        return(ret)
    } else {
        ret <- data.frame()
        for (i in 1:length(ip))
        {
            r <- freegeoip(ip[i], format = "dataframe")
            ret <- rbind(ret, r)
        }
        return(ret)
    }
} 



 
#'getProtocolFromPort
#'
#'given a well known port number and true for TCP, False for UDP returns the protocol name that runs behind
#'
#' @param port well known port number
#' @param istcp boolean, True for TCP, False for UDP
#'
#' @return
#' @export
#'
#' @examples
getProtocolFromPort <- function(port, istcp) { #parametre download
  url <- "http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv"
  oldcsvfile <- "./data/service-names-port-numbers.csv"
  newcsvfile <- "./data/service-names-port-numbers-new.csv"
  warnmessage <- "Downloading IANA ports CSV file failed, using the local file with date 2016-06-01"
  downloadfailed <- FALSE
  tryCatch({
    #download.file(url, newcsvfile)
  }, 
  error = function(e){
    downloadfailed <<- TRUE
    warning(warnmessage)
  })
  if (downloadfailed) {newcsvfile <- oldcsvfile}
  df <- read.csv(file=newcsvfile, header=TRUE, sep=",")
  df <-subset(df, select=c("Service.Name", "Port.Number", "Transport.Protocol"))
  df <- subset(df, Port.Number==port)
  df <- subset(df, Transport.Protocol==ifelse(istcp,"tcp","udp"))
  res <- as.character(df$Service.Name)
  return(res)
} 


