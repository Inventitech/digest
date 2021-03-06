
##  digest -- hash digest functions for R
##
##  Copyright (C) 2003 - 2016  Dirk Eddelbuettel <edd@debian.org>
##
##  This file is part of digest.
##
##  digest is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 2 of the License, or
##  (at your option) any later version.
##
##  digest is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with digest.  If not, see <http://www.gnu.org/licenses/>.


digest <- function(object, algo=c("md5", "sha1", "crc32", "sha256", "sha512",
                           "xxhash32", "xxhash64", "murmur32"),
                   serialize=TRUE, file=FALSE, length=Inf,
                   skip="auto", ascii=FALSE, raw=FALSE, seed=0,
                   errormode=c("stop","warn","silent")) {

    algo <- match.arg(algo)
    errormode <- match.arg(errormode)

    .errorhandler <- function(txt, obj="", mode="stop") {
        if (mode == "stop") {
            stop(txt, obj, call.=FALSE)
        } else if (mode == "warn") {
            warning(txt, obj, call.=FALSE)  # nocov
            return(invisible(NA))           # nocov
        } else {
            return(invisible(NULL))         # nocov
        }
    }

    if (is.infinite(length)) {
        length <- -1               # internally we use -1 for infinite len
    }

    if (is.character(file) && missing(object)) {
        object <- file                  # nocov
        file <- TRUE                  	# nocov
    }

    if (serialize && !file) {
        ## support the 'nosharing' option in pqR's base::serialize()
        object <- if ("nosharing" %in% names(formals(base::serialize)))
                      base::serialize (object, connection=NULL, ascii=ascii, nosharing=TRUE)
                  else
                      base::serialize (object, connection=NULL, ascii=ascii)
        ## we support raw vectors, so no mangling of 'object' is necessary
        ## regardless of R version
        ## skip="auto" - skips the serialization header [SU]
        if (any(!is.na(pmatch(skip,"auto")))) {
            if (ascii) {
                ## HB 14 Mar 2007:
                ## Exclude serialization header (non-data dependent bytes but R
                ## version specific).  In ASCII, the header consists of for rows
                ## ending with a newline ('\n').  We need to skip these.
                ## The end of 4th row is *typically* within the first 18 bytes
                skip <- which(object[1:30] == as.raw(10))[4] # nocov
            } else {
                skip <- 14
            }
            ## Was: skip <- if (ascii) 18 else 14
        }
    } else if (!is.character(object) && !inherits(object,"raw")) { 
        return(.errorhandler(paste("Argument object must be of type character",	# nocov 
                                   "or raw vector if serialize is FALSE"), mode=errormode)) # nocov
    } 
    if (file && !is.character(object))
        return(.errorhandler("file=TRUE can only be used with a character object",
                             mode=errormode))
    ## HB 14 Mar 2007:  null op, only turned to char if alreadt char
    ##if (!inherits(object,"raw"))
    ##  object <- as.character(object)
    algoint <- switch(algo,
                      md5=1,
                      sha1=2,
                      crc32=3,
                      sha256=4,
                      sha512=5,
                      xxhash32=6,
                      xxhash64=7,
                      murmur32=8)
    if (file) {
        algoint <- algoint+100
        object <- path.expand(object)
        if (!file.exists(object)) {
            return(.errorhandler("The file does not exist: ", object, mode=errormode)) # nocov
        }
        if (!isTRUE(!file.info(object)$isdir)) {
            return(.errorhandler("The specified pathname is not a file: ", # nocov 
                                 object, mode=errormode))                  # nocov
        }
        if (file.access(object, 4)) {
            return(.errorhandler("The specified file is not readable: ",
                                 object, mode=errormode))
        }
    }
    ## if skip is auto (or any other text for that matter), we just turn it
    ## into 0 because auto should have been converted into a number earlier
    ## if it was valid [SU]
    if (is.character(skip)) skip <- 0
    val <- .Call(digest_impl,
                 object,
                 as.integer(algoint),
                 as.integer(length),
                 as.integer(skip),
                 as.integer(raw),
                 as.integer(seed))
    return(val)
}
