#!/bin/bash
##################################################################
# Copyright (c) Diyotta Inc. All rights reserved.                #
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.  #
#                                                                #
# This source file is proprietary property of Diyotta, Inc.      #
# This code is cannot be copied and/or redistributed and/or      #
# modified without prior permission from  Diyotta.               #
# Please contact us at contact@diyotta.com or                    #
# visit www.diyotta.com you need additional information.         #
##################################################################


#convert string to uppercase
fn_uppercase()
{
        opvar=`echo "$1" | tr '[:lower:]' '[:upper:]'`
        echo $opvar

}

#convert string to lowercase
fn_lowercase()
{
        opvar=`echo "$1" | tr '[:upper:]' '[:lower:]'`
        echo $opvar

}

#Function will create directory if not exist
fn_createdir()
{
		path=$1
		if [ ! -d $path ]
		then
			mkdir -p $path
		fi
}

#Return error message if required arguments missing
fn_missingargs()
{
	ipstr=$1
	
	case $ipstr in
		"PROJECT")
			echo "To Export PROJECT - Export_Object_Name is Mandatory"
			exit 1
			;;
		"LAYER")
			echo "To Export LAYER - Export_Object_Name and Project are Mandatory details"
			exit 1
			;;
		"JOBFLOW")
			echo "To Export JOBFLOW - Export_Object_Name,Project and layer are Mandatory details"
			exit 1
			;;
		"DATAFLOW")
			echo "To Export DATAFLOW - Export_Object_Name,Project and layer are Mandatory details"
			exit 1
			;;
		"DOBJ")
			echo "To Export DOBJ - Export_Object_Name,project,Datapoint,Group and Object_type are Mandatory details"
			exit 1
			;;
		"DATAPOINT")
			echo "To Export DATAPOINT - Export_Object_Name,project,Group and Object_type are Mandatory details"
			exit 1
			;;
		*)
			echo "Mandatory params missing"
			exit 1
		esac
}



#Script starts here
exec &> /app/diyotta_dev/export.log

#Send error message and exit if required arguments are not passed
if [[ $# -lt 2 ]]; then
   echo "Usage : diy_export.sh <export_list_file> <Repository location>"
   exit 1
fi

#Skip the first line(header) from the export list file
sed '1d' $1 > /app/diyotta_dev/export.lst

#Assign the repository location to a variable
target_location=$2

tmp_home="/app/diyotta_dev"

#Remove temp file if it already exist
if [ -f $tmp_home/tmp_dicmd.lst ] ; then
    rm -r $tmp_home/tmp_dicmd.lst
fi

#Loop through the export list and return error message if any
while read -r line
do
        exptype=`echo $line | cut -d ',' -f1`
        export_object_type=$(fn_uppercase $exptype)
		
		objname=`echo $line | cut -d ',' -f2`
        export_object_name=$(fn_lowercase $objname)

        prj=`echo $line | cut -d ',' -f3`
        project_name=$(fn_uppercase $prj)

        layer=`echo $line | cut -d ',' -f4`
        layer_name=$(fn_lowercase $layer)
		
		dtpoint=`echo $line | cut -d ',' -f5`
        data_point=$(fn_lowercase $dtpoint)

        grpname=`echo $line | cut -d ',' -f6`
        group_name=$(fn_lowercase $grpname)

        objtype=`echo $line | cut -d ',' -f7`
        object_type=$(fn_uppercase $objtype)

#Check export_object_type is onscope 
if [[ ! "$export_object_type" =~ ^(PROJECT|LAYER|JOBFLOW|DATAFLOW|DOBJ|DATAPOINT)$ ]];
then
        echo "Only below object can be exported:"
        echo "          project   - to export entire project"
        echo "          layer     - to export entire layer"
        echo "          jobflow   - to export jobflow"
        echo "          dataflow  - to export dataflow"
        echo "          dobj      - to export dobj"
        echo "          datapoint - to export datapoint"
        exit 1
fi

#Check object_type is onscope
if [[ "$export_object_type" =~ ^(DOBJ|DATAPOINT)$ ]];
then
        if [[ ! "$object_type" =~ ^(SN|SS|OR|FF|PG|MS|JS|RT|TD|NZ)$ ]];
        then
                echo "Object type should be one of the below:"
                echo "          SN - Snowflake"
                echo "          SS - Sqlserver"
                echo "          OR - Oracle"
				echo "          FF - FlatFile"
				echo "          PG - POSTGRESQL"
				echo "          MS - MSSQL"
				echo "          JS - JSON"
				echo "          RT - REST"
                echo "          TD - Teradata"
                echo "          NZ - Netezza"
                exit 1
        fi
fi

#Check the project directory exists, if not create it
if [ "$export_object_type" == "PROJECT" ]
then 
	project_dir=$(fn_uppercase $export_object_name)
else
	project_dir=$project_name
fi

#call function to create directory if not exist
fn_createdir ${target_location}/${project_dir}

if [ "$export_object_type" == "PROJECT" ]
then
		prj_dir=$(fn_uppercase $export_object_name)
        filename="${target_location}/${prj_dir}/project/${export_object_name}.json"
		
		#call function to create directory if not exist
		fn_createdir ${target_location}/${prj_dir}/project
		
        if [[ -z $export_object_name ]];
        then
                fn_missingargs $export_object_type
        fi
		
        echo "dicmd export -p $export_object_name -f $filename" >> $tmp_home/tmp_dicmd.lst

elif [ "$export_object_type" == "LAYER" ]
then
        filename="${target_location}/${project_name}/layer/${export_object_name}.json"
		
		#call function to create directory if not exist
		fn_createdir ${target_location}/${project_name}/layer
		
        if [[ -z $project_name || -z $export_object_name ]];
        then
                fn_missingargs $export_object_type
        fi
		
        echo "dicmd export -p $project_name -l $export_object_name -f $filename" >> $tmp_home/tmp_dicmd.lst

elif [ "$export_object_type" == "JOBFLOW" ]
then
        filename="${target_location}/${project_name}/jobflow/${export_object_name}.json"
		
		#call function to create directory if not exist
		fn_createdir ${target_location}/${project_name}/jobflow
		
        if [[ -z $project_name || -z $layer_name || -z $export_object_name ]];
        then
                fn_missingargs $export_object_type
        fi
		
        echo "dicmd export -p $project_name -l $layer -o $export_object_type -n $export_object_name -f $filename" >> $tmp_home/tmp_dicmd.lst

elif [ "$export_object_type" == "DATAFLOW" ]
then
        filename="${target_location}/${project_name}/dataflow/${export_object_name}.json"
		
		#call function to create directory if not exist
		fn_createdir ${target_location}/${project_name}/dataflow
		
        if [[ -z $project_name || -z $layer_name || -z $export_object_name ]];
        then
                fn_missingargs $export_object_type
        fi
		
        echo "dicmd export -p $project_name -l $layer -o $export_object_type -n $export_object_name -f $filename" >> $tmp_home/tmp_dicmd.lst

elif [ "$export_object_type" == "DOBJ" ]
then
        filename="${target_location}/${project_name}/dataobject/${data_point}_${group_name}_${export_object_name}.json"
		
		#call function to create directory if not exist
		fn_createdir ${target_location}/${project_name}/dataobject
		
        if [[ -z $project_name || -z $object_type || -z $data_point || -z $group_name || -z $export_object_name ]];
        then
                fn_missingargs $export_object_type
        fi
		
        echo "dicmd export -p $project_name -o $export_object_type -t $object_type -g $group_name -c $data_point -n $export_object_name -f $filename" >> $tmp_home/tmp_dicmd.lst

elif [ "$export_object_type" == "DATAPOINT" ]
then
        obj_type=$(fn_lowercase $object_type)
        filename="${target_location}/${project_name}/datapoint/${obj_type}_${group_name}_${export_object_name}.json"
		
		#call function to create directory if not exist
		fn_createdir ${target_location}/${project_name}/datapoint
		
        if [[ -z $project_name || -z $object_type || -z $group_name || -z $export_object_name ]];
        then
                fn_missingargs $export_object_type
        fi
		
        echo "dicmd export -p $project_name -o $export_object_type -t $object_type -g $group_name -n $export_object_name -f $filename" >> $tmp_home/tmp_dicmd.lst

else
        echo "Invalid export_object_type"
fi


done < $tmp_home/export.lst

#Loop through all the dicmd export command generated and export the object
while read -r line
do
        echo -e "Exporting: \n \t $line "  #save in logfile
        $line #save in logfile
done < $tmp_home/tmp_dicmd.lst