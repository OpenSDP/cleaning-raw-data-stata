/* 
OpenSDP Data Janitor Tutorial
Cleaning Raw Data in Stata
*/


/* INTRODUCTION */

/* This tutorial has two objectives. The first objective is to demonstrate the 
process of cleaning a raw data file from start to finish. This includes checking 
and cleaning key variables, formatting, coding, renaming, and labeling 
variables, exploring data structure, and applying decision rules to simplify 
data where necessary.

You can group the cleaning operations into two parts: first, "column cleaning," 
or examining, formatting, cleaning and labeling each variable as appropriate; 
and second, "row cleaning," or examining the data's structure and retaining or 
editing specific observations or groups of observations, with the goal of making 
the data internally consistent and simplifying its structure if necessary. In 
both column cleaning and row cleaning, you'll need to make trade-offs between 
retaining all the information in the original raw dataset, and making changes to
the data to make it tractable for later analysis. 

Because the tutorial shows how to clean test score data, after doing row 
cleaning it ends with a demonstration of how to use the reshape command to 
change the structure of the data from "long" format to "wide" format--from one 
record per student per test to one record per student per year, with multiple
test score variables. The end result is a cleaned file that is ready to be 
merged with other cleaned data files to build an analysis file.

The second objective of this tutorial is to to demonstrate some features of 
Stata which are critical for writing efficient code, including loops and global 
and local macros. It also demonstrates the syntax for a number of commands 
needed for data cleaning--for example, commands to convert data to and from 
string format, set numeric display formats, and convert variables into Stata 
date format. 

The code used in this tutorial is necessarily specific to the particular dataset 
being cleaned, in this case a file of synthetic student test scores. Thus the 
overall cleaning process shown is only partially generalizable to other raw data 
files. Test score files from other sources will typically need to be cleaned 
somewhat differently because of differences in structure, variables, 
missingness, data formats, and other issues. Other types of data, for 
example student demographics or enrollment files, typically require different 
types of data checks and cleaning operations. 

This tutorial assumes that you have completed the Data Exploration, Combining 
Files, and Nearly Unique tutorials in the OpenSDP Data Janitor series, and that 
you are comfortable opening, editing, saving, and running a Stata do file. Even 
if you haven't completed those tutorials, though, you will still be able to work 
through this one. If any of the Stata commands are unfamiliar to you, type help 
followed by the name of the command in Stata's Command window to get more 
information.

The Data Janitor tutorial series does not explicitly deal with questions of good 
coding style. When you are drawing on what you have learned from the series to 
write your own do files, you'll quickly discover that developing and adhering to 
a consistent set of style guidelines will make your code easier to read, edit, 
and understand. Train yourself to use white space (blank lines), indentation, 
and comments consistently in your code. Comments, indicated in Stata by a double 
slash //, paired /* and */ symbols, or asterisks *, are ignored by Stata but are 
critical for explaining each step of a program to human readers. Note that the 
comments in this tutorial are long and discursive; in your own do files, your 
comments should be similarly ubiquitous, but succinct. 

Unlike the previous tutorials in the series, to run this tutorial you won't be 
clicking on commands in Stata's Viewer window; instead, you will select lines of 
text in the do file editor and then run those lines by pressing Control-d or 
clicking the Execute(Do) button in the toolbar. This has the advantage of 
allowing you to run an entire block of code rather than a single line at a time. 
If you press Control-d or the Execute(Do) button without selecting any lines of 
code, the entire do file will run.

Work through the do file one or a few lines at a time, reading the comments and 
making sure you understand what each section of code does. In addition to 
running the lines of code in the tutorial, follow the instructions preceded by 
the --> symbols. As you work, explore the data to see how the data cleaning 
commands change the data. The tutorial includes some data exploration 
commands to verify that the data edits work as intended, but feel free to 
perform additional interactive checks or make edits to this file. */


/* GETTING STARTED */

/* This tutorial opens, edits and saves a number of files. The files are 
stored in several different subdirectories: programs (for Stata do files), data 
(for raw and cleaned data files), log_files (for a log of your program commands
and the resulting Stata output), and tables_figures (for graphs). In order for 
Stata to interpret the file paths in the tutorial correctly, the working 
directory should be set to the directory that includes this tutorial program, 
cleaning_raw_data_XX.do. If you started Stata by double-clicking on that file, 
the working directory will be set correctly. Use the pwd (print working
directory) and dir (directory) commands to verify that the working directory 
is the programs subdirectory which contains cleaning_raw_data_XX.do. If the 
working directory is not correct, use the cd (change directory) command to 
navigate to the cleaning_raw_data/programs subdirectory, or close Stata and 
reopen it by double clicking on the tutorial file. If Stata tries to run the 
tutorial do file rather than simply opening it in the do file editor, 
right-click on the file and choose "Edit" to open it instead. */

	pwd
	dir

/* Before you start the tutorial, save the tutorial do file under a new name. 

--> Choose "Save as..." under the Editor window file menu, and replace the "XX" 
		in the filename with your initials. 
	
This will ensure that you won't overwrite the original tutorial file if you 
decide to make edits and save them. Note that you can save do files by pressing 
Control-s or choosing the save icon on the do file editor toolbar, and you 
should do this regularly as you are working. You can also set Stata to save the 
do file every time it is run by changing a setting in the Preferences section of 
the Edit menu. 

Just as the save icon on the Editor window toolbar saves the current do file, 
the save icon in the main Stata window saves the dataset currently in memory. 
You should usually not save data files interactively, though, because that means 
you won't be able to replicate your changes. Instead, load, edit, and then save 
data (using a new filename for the cleaned data) with commands in a do file like 
this one, so that you will always be able to generate the same cleaned files 
from your raw data files and will have a record of your work. */


/* SET UP */

/* Start the do file with a series of setup commands. */

	clear all
	capture log close
	set more off
	set type double
	set seed 42
	global logdate: display %tdCCYYNNDD date("$S_DATE","DMY")
	
/* These commands are optional, but useful. 

	* clear all removes any data from memory.
	
	* capture can be put in front of any Stata command to suppress output to the 
		results window and prevent the do file from aborting if the command causes 
		an error. In this case, capture log close closes any log file that is 
		currently open. If there is no log file open, Stata ignores that error and 
		keeps running the do file.
	
	* set type double increases the number of digits Stata stores when it 
		generates a new variable. This increases the size of the dataset, but you 
		can use the compress command at the end of the do file before you save the 
		cleaned data file to downgrade the storage type for each variable to the 
		most efficient type that does not cause loss of information. 
	  
	* set seed provides a seed for Stata's random number functions. It ensures 
		that Stata will perform random actions, such as choosing a record sort order 
		when values are tied, in the same way each time commands are run. 
	
	* set more off prevents Stata from pausing the output display.
	
	* global is a command that takes a string and labels it so that you can 
		refer to it later. The labeled string is referred to as a global macro. The 
		term global refers to the fact that the macro string remains defined for the 
		entire length of your Stata session, even if you are working with different 
		do files and datasets. 
	  
	  The global command can assign a name to a string directly, or evaluate 
		expressions or commands that generate strings. You can read about the 
		various syntax options for the global command by typing "help global" in the 
		Command window, or read about global and local macros in the Stata User's 
		Guide. Here, logdate is the name of the global macro. It contains the output 
		of a display command which formats the system date in a way that makes it 
		convenient for use in filenames. 
		
		You can refer to the contents of a global macro by prefixing the macro name 
		with the $ symbol. If a macro is undefined, Stata will read it as empty. 
		That is, it will ignore the reference to the macro, and will not generate an 
		error.
	  
--> Type "display $logdate" (without the quotes) in the Command window AFTER you 
		run the setup commands. If you haven't done so already, you can run the 
		lines by selecting them and then pressing Control-d or clicking the 
		Execute(do) button in the toolbar. */

/* Open a log file to store the results of your Stata session. The log file is 
optional, but can be useful because it stores all of Stata's output so that you 
can review it later. ../log_files is a relative filepath which navigates Stata 
one level up from the programs directory which contains this tutorial do file, 
and then one level down to the log_files directory. Invoking the $logdate macro 
includes today's date in the filename of the log file. */

	log using "../log_files/cleaning_raw_data_$logdate.log", text replace
	
/* Next, get ready to load the data. You will be loading five years of raw test 
score data from a fictitious large school district. This data includes all the 
test scores for all assessments, but you are particularly interested in the 
state math and ELA test scores for students in grades 3-8. 

Often when you clean a raw data file of data extracted from a student 
information system or other source, you review and clean each of the variables 
but keep the basic structure of the file the same. In the case of transactional 
data like test scores, though, there are extra steps before you can merge the 
data with other files into an analysis file. You will need to restrict the 
sample and restructure of the data. Your goal is to make a cleaned test score 
file with one record per student per year. The file should include only math and 
ELA state test scores for students in grades 3 through 8. 


/* LOAD DATA */

Often you will receive raw data in separate annual text files, in comma 
delimited format. When that happens, you can use the import delimited command to 
convert the files into Stata format, and the append command to combine them. In 
this case the raw data is already in a single Stata-formatted file. Load the 
data and explore the file to review the variables and their formats. */

	dir ../data/raw/
	
	use "../data/raw/TEST_2006_2010", clear
	describe
	codebook
	browse
	
/*
--> After you run the browse command, add an asterisk in front of it to turn the 
line into a comment: *browse. This will keep the browse window from opening when 
you run the do file next time, but will let you keep the command in the do file 
in case you want to remind yourself to use it when you are reviewing and 
cleaning an updated dataset.
		
You can see from your quick review that all the variables are strings, and that 
some seem to have extra spaces. You can use the trim function to strip away the 
extra spaces. It's probably quickest to just apply the command to all of the 
variables. Here's the syntax to loop through all the variables and trim them. To 
run the loop, you need to select all three lines at once and run them. */

	foreach var of varlist _all {
		replace `var' = trim(`var')
	}

/* Here the syntax _all refers to a list that includes the names of all the 
variables in the dataset. The loop uses the `' notation to successively replace 
the text `var' with each variable name in the dataset. If you look at the 
output, you'll see that Stata only echos the commands in the loop once, at the 
beginning, and then displays the command output for each of the loop iterations. 
Three variables were trimmed, and the others didn't have leading or trailing 
spaces and weren't changed.

This display behavior can make the code in loops difficult to troubleshoot. 
Nonetheless, anytime you are performing the same operation on a number of 
variables, it's usually worth writing a loop. For a short loop, start by testing 
your code on a single variable: */

	replace collection_code = trim (collection_code)
	
/* Oops, that didn't work. 

--> Edit the code by removing the extra space before the parentheses, and run 
the command again. 

Then, add the looping code to process multiple variables,  replacing the 
variable name with the var from the loop command surrounded by the `' symbols: 
*/

	foreach var of varlist _all {
		replace `var' = trim(`var')
	}
	
/* Voila! For longer, more complicated loops that have already been written, you 
can troubleshoot them by temporarily removing the looping function by commenting 
out the looping syntax (the lines with curly braces): */
	
	*foreach var of varlist _all {
		display "`var'"
		replace `var' = trim(`var')
	*}

/* Then when you select and run the code, only the lines in the body of the loop 
will run. You saw that Stata generated an error when you tried to run just the 
body of the loop above. That is because the replace command expected a variable 
name, and Stata interpreted `var' as being an empty local macro.

--> Add an asterisk to the display and replace lines of code above to turn them 
into comments, so that the error won't occur again when you try to run the 
whole do file later.

A local macro is similar to a global macro: it is a name that can be used to 
refer to a string of characters. In this case the for loop command successively 
defines the local macro named var as the names of the variables in the dataset. 
Within the loop, you can refer to the macro by enclosing the macro name with the 
` and ' symbols, and Stata will replace the macro name with the actual macro 
string. Like a global macro, Stata interprets an undefined local macro as being 
empty and ignores it. 

To test the body of your loop as you intended, you need to add a local macro 
definition at the beginning that refers to just one variable name, since the for 
loop syntax is commented out and isn't taking care of the macro definition for 
you: */

	*foreach var of varlist _all {
	local var collection_code
		display "`var'"
		replace `var' = trim(`var')
	*}
	
/* Now you can see the output of code in the body of the loop after each line. 
For short loops this isn't important, but for very long loops this approach can 
be very helpful for debugging your code. Once you know the code is working the 
way you want, you can re-activate the looping code by removing the comment 
symbols and deleting the local command: */

	foreach var of varlist _all {
		display "`var'"
		replace `var' = trim(`var')
	}
	
/* Since we had already trimmed the variables, there were no changes made. Two 
more things about local macros and loops are worth noting. First, local macros 
are called that because they are defined locally. You need to run the code that 
defines a local macro at the same time that you run the code that includes the 
reference to it, or Stata will just read it as being empty, and ignore it. In 
every other way, the syntax for defining and using global and local macros is 
the same, though Stata only uses local macros as loop indexes.

Second, Stata has a number of different ways that you can define a loop in your 
program, with slightly different syntaxes for each method. Type "help foreach" 
or "help forvalues" in the Command window or read the manual sections on loops 
before writing your own looping code. Stata will let you loop through a list of 
variables, a list of numbers, or even just a list of text strings.

--> Learning about looping and local macros at the same time is a bit of a lift. 
To reinforce how the local command works have Stata print your name to the 
results window by replacing the XXX below with your name. */

	local myname "XXX"
	display "My name is `myname'."
	
	
/* CLEAN VARIABLES */

/* Getting back to data cleaning, now that the variables are trimmed, it's 
possible to check and see if all the variables are necessary and meaningful. 
First check to see which years of data are included in the file, and then check 
the distribution of some of the variables that you suspect may be uninteresting 
based on your review of the output of the codebook command. */

	tab reporting_year, mi
	tab reporting_year collection_code, mi
	tab reporting_year extraction_date, mi
		
/* Collection code and extraction date don't add much information, so it's okay 
to drop them.*/

	drop collection_code extraction_date
	
/* Go through the remaining variables one at a time to examine their 
distribution and format. Rename them according to Strategic Data Project 
variable naming conventions and reformat them as necessary. (Develop your own 
conventions for variable names when you are cleaning your own data--make them
informative and try to be consistent in how you name variables across projects.) 

After the individual variables are cleaned and formatted (column cleaning), 
you'll do a second cleaning pass to restrict the sample to the tests of 
interest, apply decision rules to simplify the structure of the data (row 
cleaning), and then reshape the data from one record per student per test to one 
record per student per year. 

Start by cleaning up reporting year. According to the person who pulled the 
data for you, this corresponds to school year (using the convention that the 
school year is referred to by the calendar year of the spring semester). You'll 
verify this is true for the tests you are interested in after you have cleaned 
the test date variable and can compare test year and school year. School year 
will be one of the key variables of your cleaned data file, so it is good that 
there are no missing values. */

	tab reporting_year, mi
	destring reporting_year, replace
	rename reporting_year school_year
	label var school_year "School Year"
	
/* Then clean student ID. Student ID will be the other key variable for your 
cleaned data file. Use the assert command to verify that the trimmed, destrung 
variable has no missing values. */
    
	destring student_id, replace
	assert student_id != .
	rename student_id sid
	label var sid "Student ID"
	
/* It seems like that's all you need to do to clean the student ID variable, but 
try browsing the data. */

	browse
	
/* The student IDs are displaying in scientific notation, which isn't very 
helpful. Stata will allow you to apply a display format to the IDs so all the 
digits will show, but you need to know the number of digits to do so. Stata has 
a number of useful string functions, including one to check the length of 
strings. But, you've already converted the IDs to numeric format so you can't 
use those functions now. Ideally you'd like to go back one step, before the 
destring command, and insert a line of code to check the number of digits in the 
student ID. Then you can destring the variable and apply a display format, using 
what you learn about the number of digits. 

To insert and then check that line of code you should re-run the do file from 
the beginning. This will load the data in its original state and then re-apply 
all the data cleaning changes up to the current point. To do this you could 
either select all of the do file up to that point and run the selected lines, or 
you could "comment out" the remainder of the do file and then run the whole 
file, with Stata ignoring the commented out lines after the section you are 
working on. Do the latter.

--> On the line before "destring student_id, replace", type the characters / 
		and * (with no space in between) to open a block comment. 

You should see all of the commands in the rest of the tutorial change from blue 
(commands) to green (comments). 

--> Then, without selecting any text, press either Control-d or the Execute(do) 
		button in the toolbar, and Stata will re-run all the commands from the 
		beginning of the do file up to that point. 

--> Delete the /  and * symbols that you added, and then add the line 
		"describe student_id" before the line "destring student_id, replace", and 
		re-run that block of code. 

This will tell you how many characters long the student ID variable is.

Using this process to write or review code--writing and running a few lines at a 
time, until you find a time when you need to "reset" your work by reloading the 
data and re-running everything up to the beginning of the section you are 
currently working on--is pretty typical.

--> You'll notice when you are running the entire do file that the codebook 
command near the beginning runs slowly. You can add an asterisk in front of it 
to comment it out for now (though that means the output won't appear in your log 
file). 

--> You can also add asterisks to comment out browse commands (or delete them), 
		to keep the browser window from opening while the do file runs.

So, the student ID has no more than nine digits (the describe command classified 
it as a str9 variable). Now that it's been converted to a number you can apply a 
display format and check the results. (You can type help format in the Command 
window for detailed information about Stata's available formats.) */

	format sid %9.0f
	browse
	
/* Next, examine and label the test ID variable. Using the sort option puts the 
most common tests at the top. You can see that some of the test IDs seem to 
consist of a subject prefix followed by a grade level (for example, MA04 for 
fourth-grade math, or RD06 for sixth-grade reading). Others (ALG1 for algebra 1 
and ALG2 for algebra 2, and USHI for US History) don't follow this format. 
Others you probably can't identify just from the test ID; you'd need to get 
additional information from the district to identify those tests. 

This raises a typical question in data cleaning: should you clean all the data 
you receive, or focus on the variables (columns) and observations (rows) that 
you think are most important for your analysis? If you are too hasty in working 
with data that you don't yet know well, you might mistakenly drop variables or 
records that you need, that help you understand the dataset, or that you might 
want later for a different project. On the other hand, data cleaning is 
labor-intensive, and it doesn't make sense to do unnecessary work. If you have 
limited time, a very rough rule of thumb is to try to clean all the records you 
receive, but focus effort on the most important variables. 

In the case of test score data, though, there's a twist if you are applying this 
rule of thumb. You're likely to be reshaping the data from test level to student 
level, so that test scores for different tests become different variables for a 
given student record in the cleaned data file. If you don't actually need all 
the test scores for every subject for every student, there is a reasonable 
argument to be made for keeping and cleaning only the records for tests you are 
interested in.

In this case, we'll stipulate that you only want the data for state Mathematics 
and English/Language Arts tests scores for grades 3-8, and that the person 
who extracted the data for you told you that the IDs for the state math and ELA 
tests are prefixed by "MA" and "RD". You'll use this information later when you 
restrict the data and then parse the test IDs to extract the subject and grade 
level. 

For now, keep data for all the tests during the "column cleaning" part of 
the data cleaning process, in case the additional tests yield some insights into 
the patterns of values for the other variables. We'll wait to drop the 
additional tests until the beginning of the "row cleaning" process. */

	tab test_id, mi sort
	tab test_id school_year, mi
	label var test_id "Test ID"

/* Convert the test_date variable to a Stata date, which is a number which gives 
the days since January 1, 1960. Stata does a good job of parsing date strings in 
different formats to define date variables, but you do need to tell it the order 
of year, month, and day. You also need to format date variables so that they 
display as dates. 

--> Browse the data between the steps below to see how the commands take 
		effect. */

	gen tempdate = date(test_date, "YMD")
	drop test_date
	rename tempdate test_date
	format test_date %td
	label var test_date "Test Date"
	
/* Check to make sure that all of the test dates fall in the correct school 
years. Stata makes it fairly easy to extract years or months from date 
variables. */

	gen testyear = year(test_date)
	replace testyear = testyear + 1 if month(test_date) > 6
	tab testyear school_year, mi 
	drop testyear
	
/* There is one case where the test year and school year are different. Examine 
this record. It is for a test occurring in June that you don't intend to keep. 
*/

	browse if testyear != school_year
	
/* Tidy up the variable order .*/

	order sid school_year test_id test_date
	
/* Examine the score variable. You will need to replace the records with the 
value "NS" with missing before you can destring the variable. Missing for a 
string variable is represented as "" (an empty string), while missing for a 
numeric variable is represented as . (period). */

	tab score, mi
	replace score = "" if score == "NS"
	destring score, replace
	rename score scale_score
	label var scale_score "Scale Score"
	
/* An important part of cleaning test score data is examining histograms of the 
test scores, to check for normal distributions, ceiling and floor effects, 
improperly labeled tests, missing values miscoded as zeros, changes in ranges, 
etc. We could do this here, but instead we'll wait until the data has been 
reshaped, because it will be somewhat easier to generate graphs for each 
subject, year and grade then. 

Clean the achievement level variable next. In Stata, the best practice for 
categorical variables like this one is to use numeric codes for each value, and 
then label each value with a description. In this case, you have the codes but 
not the descriptions. This is a fairly common data cleaning situation, and the 
the best approach is to do research or reach out to your contacts to acquire the 
missing information and then incorporate it. This helps you build a 
"self-documenting" dataset. 

Here we'll stipulate that the descriptions for achievement levels are consistent 
across tests and years: novice, developing, proficient, and advanced. Check the 
distribution of achievement levels by test ID to make sure they are reasonable. 
Destring and label the variable. */

	tab ach_level, mi
	tab test_id ach_level, mi row
	destring ach_level, replace
	label var ach_level "Test Achievement Level"
	label define ach_level_lbl 1 "Novice" 2 "Developing" 3 "Proficient" 4 "Advanced"
	label values ach_level ach_level_lbl
	tab ach_level, mi
	
/* You don't have information about the cscore and cscore_err variables, but 
based on the cscore range, cscore may be a standardized version of the scaled 
test score. The overall correlation between scaled scores and cscores is very 
low--this makes sense, since different tests have different ranges, and those 
ranges may also change across years. Checking the correlations by test and year, 
they are for the most part very close, confirming that cscore is a version of 
the test score. */

	destring cscore*, replace
	codebook cscore*
	summ cscore*, detail
	corr cscore scale_score
	bysort test_id school_year: corr cscore scale_score
	
/* A few of the tests have very low cscore correlations. Examine two of these, 
along with a test with a high correlation for comparison. */

	scatter scale_score cscore if test_id == "ENGL" | test_id == "ALG1" | ///
		test_id == "RD05", by(test_id school_year)
		
/* To examine the graphs, make the graph window full screen so it's easier to 
see the individual graphs. The explanation for the low correlation is clear: 
the problematic tests and years appear to have two different score ranges. It's 
likely that scores for two different versions of the tests were lumped together 
in the data. If you planned to use these tests in your analysis, you would need 
to find out more details about the test forms and versions for the problematic 
tests and years. */

	hist scale_score if test_id == "ENGL"
	hist cscore if test_id == "ENGL"
	
/* You might wonder if you should use the cscore variable, rather than the 
scaled score, since it appears to correct for this problem. But you don't know 
the details of how cscore was derived, and you saw in the correlation tables 
that it is missing for many tests. Even if the variable is fully populated for 
the tests you care about, as you have seen it might mask issues with those tests
that you should be aware of. You are better off using the scaled scores and 
examining them carefully for the tests you are interested in. After examining 
the scaled scores, you can derive your own standardized scores and use them to 
compare scores across tests and years. 

For now, drop the cscore variables, and make a note to yourself to inquire about 
their provenance. When making notes to yourself, it's a good idea to prefix them 
with a consistent symbol so that you can find them quickly. Here the follow-up 
reminder is preceded by ** and is not indented. */
	
	drop cscore*
**check on cscore* definitions
	
/* Clean the accommodation variable. The tabulation below demonstrates why it's 
important to check distributions by school year! Note that students without 
accommodations have a missing value, rather than zero. You need to decide 
whether you trust the variable or not. Assuming the variable is reasonably 
accurate, it's probably better to change the missing values to zero, or no, for 
the years when data is present. This will help distinguish the years that have 
no data. You should also clarify the scope of the variable in the variable 
label. */

	tab accommodation, mi
	tab school_year accommodation, mi
	replace accommodation = "1" if accommodation == "Y"
	replace accommodation = "0" if missing(accommodation) & school_year > 2008
	destring accommodation, replace
	label var accommodation "Student Had Test Accommodation (Post-2008 only)"
	
/* Finally, tidy up the fake_data indicator (all the data is fake). You won't 
have to do this with your own data, but with your own data you need to be 
mindful of confidentiality and Family Educational Rights and Privacy Act 
obligations. */

	tab fake_data, mi
	destring fake_data, replace
	label var fake_data "Simulated Data Record"
	
/*
--> Browse the data. It looks much tidier now. */


/* RESTRICT SAMPLE */

/* However, even though the variables have been examined and tidied up, we haven't 
started to verify and clean up the structure of the data yet (we've dealt with 
the columns but not the rows). Start this process by seeing if there are any 
duplicate records. */

	duplicates report

/*	There are some complete duplicates, so drop them. The end of line comments 
track the numbers of records dropped or changed during the rest of the cleaning 
process. */

	duplicates drop // 973 records dropped
		
/* Next, drop any records with missing test scores. You might be inclined to 
keep the records with missing test scores, just to signal that a student was 
considered to be enrolled in the district. However, this data is being cleaned 
in preparation for merging with other cleaned data files, including student 
enrollment data. 

Where there are conflicts, we'll stipulate that the student enrollment data will 
take priority over the test score data in verifying student presence in the 
district. Thus the test records without scores won't add useful information to 
the eventual analysis file, and dropping the empty records will help to simplify 
the file.

Here's are two different ways to identify the missing values, using the missing 
function or a comparison expression (both of these statements work the same, so 
choose either one). */

	drop if missing(scale_score) // 3042 records dropped
	drop if scale_score == .
		
/* Next, restrict the sample to just the tests that you are interested in. Check 
the test IDs first to see which ones to keep. Note the use of the substr 
(substring) function to examine just the math and reading tests. */

	tab test_id, sort mi
	tab test_id if substr(test_id, 1, 2) == "MA" | substr(test_id, 1, 2) == "RD", mi
	
/* You can see that most of the test IDs with the math and ELA subject prefixes 
also seem to include a grade level. There are two exceptions--the MA3P and 
RD3P tests, which occur in some but not all years. You can also see that there 
are very few 10th grade scores for the tests with the MA and RD prefixes, though 
there are subject specific tests such as GEOM and ENGL which likely correspond 
to upper grade level math and ELA courses. Check the distribution of MA and RD 
tests by year. */

	tab test_id school_year if substr(test_id, 1, 2) == "MA" | ///
		substr(test_id, 1, 2) == "RD", mi

/*	The counts for MA03 and RD03 are consistent with counts for other grades, 
which suggests that the RD3P and MA3P are additional tests, rather than 
substitutes, if they in fact correspond to 3rd grade tests. Check the months 
when the tests occur. */

	gen testmonth = month(test_date)
	foreach test in "RD3P" "RD03" "MA3P" "MA03" {
		display "`test'"
		tab testmonth if test_id == "`test'", mi
	}
	drop testmonth
**verify that MA3P and RD3P are 3rd grade pre-tests
	
/* It looks like the "3P" tests are beginning of year pre-tests; make a note to 
yourself to verify this. For this project, we'll stipulate that you are only 
interested in the end of year scores. You now have the information you need to 
identify 3rd through 8th grade math and ELA end of year test scores. 

In the interest of demonstrating as many Stata tricks as possible, here are five 
different ways to restrict the sample to the tests of interest. If you run all 
the code, only the first set of commands will have any effect. 

The code below uses the /// continuation symbol to allow you to break a Stata 
command over multiple lines. You don't need to do this, but it's good practice 
to make sure that your code doesn't run off the right margin of your screen--
except when it's not possible to break a line, people should not have to scroll 
horizontally to read your code. Note the indentation of the lines after the 
continuation symbol, to make the code easier to read. */

	keep if test_id == "MA03" | ///
		test_id == "MA04" | ///
		test_id == "MA05" | ///
		test_id == "MA06" | ///
		test_id == "MA07" | ///
		test_id == "MA08" | ///
		test_id == "RD03" | ///
		test_id == "RD04" | ///
		test_id == "RD05" | ///
		test_id == "RD06" | ///
		test_id == "RD07" | ///
		test_id == "RD08" // 225,642 records dropped
	tab test_id school_year, mi
		
/* This code uses the #delimit command to temporarily change Stata's end-of-line 
symbol from a carriage return (cr) to a semicolon (;) and then change it back 
again. This syntax can be very useful for long commands in Stata, for example 
making complicated graphs. */

	#delimit ;
	keep if test_id == "MA03" | 
		test_id == "MA04" | 
		test_id == "MA05" | 
		test_id == "MA06" | 
		test_id == "MA07" | 
		test_id == "MA08" | 
		test_id == "RD03" | 
		test_id == "RD04" | 
		test_id == "RD05" | 
		test_id == "RD06" | 
		test_id == "RD07" | 
		test_id == "RD08" ;
	#delimit cr
	tab test_id school_year, mi
	
/* This version of the record selection code uses the inlist function. It's 
divided into two parts combined with the or (|) symbol because inlist only 
allows up to 10 arguments if they are strings. */

	keep if inlist(test_id,"MA03","MA04","MA05","MA06","MA07","MA08") | ///
		inlist(test_id,"RD03","RD04","RD05","RD06","RD07","RD08")
	tab test_id school_year, mi
		
/* This is a rather contrived example, but it shows how you can use a global 
macro to store a useful list of values or variables, and how you can use a 
binary indicator variable to tag specific records. Note that since the tag 
variable is defined as either zero or one for every record, you don't need to 
use the syntax "keep if tag == 1" to keep the tagged records. Stata will 
interpret the expression "tag" as false if tag is zero, and true if tag is one. 
If tag has missing values, you can't use the "keep if tag" syntax, because Stata 
interprets any number larger than zero as true, and Stata defines missing as a 
very large number. */

	global tests "MA03 MA04 MA05 MA06 MA07 MA08 RD03 RD04 RD05 RD06 RD07 RD08"
	gen tag = 0
	foreach test in $tests {
		replace tag = 1 if test_id == "`test'"
	}
	keep if tag
	tab test_id school_year, mi
	drop tag

/* Finally, this is an even more contrived example, but it includes nested 
loops! Note the use of the assert command and strlen function to verify the 
number of characters in the test ID, and how the substr function can count from 
either the beginning or end of the string. (Type "help substr" for details.) 
Also note how the nested real and substring functions are used to extract the 
grade and convert it to a number. */

	gen tag = 0
	assert strlen(test_id) == 4
	foreach subject in "MA" "RD" {
		forval grade = 3/8 {
			replace tag = 1 if substr(test_id, 1,2) == "`subject'" & ///
				real(substr(test_id, -1, 1)) == `grade'
		}
	}
	keep if tag
	tab test_id school_year, mi
	drop tag
	
/* 
--> Comment out and then run different sections of the do file from the 
		beginning to verify that at least two of these code examples keep the same 
		records, based on the number of observations deleted and the table of test 
		IDs and school years. */
		

/* SIMPLIFY STRUCTURE */

/* Your goal is to eventually restructure the data so that you have one record 
per student per year. What is the current structure of the data? You might 
expect that each student would take the state test in math and reading only once 
each year. Is this true? Check to see how many state tests students take each 
year using the duplicates command to see how many records there are for each 
student-year combination. Most students take two tests per year, but some have 
more than two test score records. */

	duplicates report sid school_year
	
/* Are there any cases where students have more than one test score for the same 
test? */

	duplicates report sid school_year test_id
	
/* Based on the output of the duplicates command, there are about 42 thousand 
records which have duplicated student ID, school year, and test_id values, or 
about 21,000 thousand "extra" records. Are these because of test taking on 
multiple test dates? */

	duplicates report sid school_year test_id test_date
	
/* This shows that there are still a large handful of cases where students took 
the same test on the same date. We know these records aren't exactly the same, 
because we already dropped duplicate records. Use the duplicates tag option and 
then browse the records to get a sense of differences between the 
near-duplicates. */

	sort sid school_year test_id
	duplicates tag sid school_year test_id test_date, gen(tag)
	browse if tag
	drop tag

/* It looks as if there are a number of cases where students have multiple test 
instances on the same day, but different scores. This is an implausible 
situation. It may relate to data errors. How should you handle this? You could 
reach out to the district's assessment department to discover why there are so 
many near-duplicate records, but getting an answer to your query will take time, 
and might not fully resolve the issue. Should you ask for a new data pull? You 
could consider doing so. But the "extra" near-duplicate records make up only 1.4 
percent of the total records. 

If you believe that most of the student data is accurate, having inaccurate data 
for one or two percent of your dataset is unlikely to bias your results if you 
are interested in analyzing patterns in the data rather than developing 
individual accountability results. Rather than calling a halt to the data 
cleaning work, it makes sense to proceed by applying a decision rule to choose 
a single test score record in cases where there are near-duplicates. 

This choice demonstrates three data cleaning truisms. First, you are often 
faced with making a tradeoff between losing some information and developing a 
tractable dataset. Second, education data is of varying, and often poor, 
quality. The timeline for your analysis project is probably shorter than the 
timeline for improving data governance, data collection, and data management in 
your organization. Nonetheless, even imperfect data can yield meaningful and 
actionable information, and using that data in analysis will help to create the 
demand for better-quality data over time. And third, it's always a good idea to 
learn as much as you can about the data you are working with from others who 
know it better. You may not be able to get answers right away, though, so you 
should comment and organize your cleaning code so that you can modify it easily 
when or if you learn more about the data, and re-run it easily if you receive 
updated data.

Before starting to apply decision rules to pick specific test instances, check 
to see if there are any cases where the test scores, test IDs, and test dates 
are all the same, and some other variable is different. */

	duplicates report sid school_year test_id test_date scale_score
	isid sid school_year test_id test_date scale_score
	
/* So, the data is unique at the student-year-test-date-score level. The 
duplicates command provides most of the information needed to determine the 
structure of the data, but here's the syntax for asking a question about the 
number of tests taken by students in a different way. */

	egen numtest = nvals(test_id test_date scale_score), by(sid school_year)
	tab numtest, mi
	drop numtest

/* The nvals option of the egen command is extremely useful in exploring 
education data, which tends to have nested structures, because it allows you to 
ask questions like "how many classes do teachers teach?" and "how many students 
are there in a class?" In this case numtest answers the question: what is the 
distribution of the number of tests taken for each student and school year? Note 
that nvals isn't part of the basic Stata software, so if the command above 
didn't work with your version of Stata, you may need to install the egenmore 
package. If so, remove the asterisk before the following command and run it. */

	*ssc install egenmore
	
/* Another use of nvals for this data is to check how many test dates there are 
for a given test id. */

	egen numdate = nvals(test_date), by(test_id school_year)
	tab numdate, mi
	
/* This is interesting--there are either two or four test dates for a given test 
in a given year. Is there a pattern by school year? */

	tab school_year numdate, mi
	drop numdate
	
/* In fact, there is. Part of data cleaning is making sure that the ranges of 
values for variables are reasonable, and though we reformatted the test date 
variable, we waited to inspect it in detail. This is partly because test dates 
are especially relevant to the "row cleaning" aspect of test data cleaning, 
and partly because examining test dates is easier now that there are fewer 
tests. Check the distribution of test dates by test ID. They look reasonable. 
All the test dates are in May or June, and there are two test dates in early 
years and four test dates in later years. */

	tab test_date test_id, mi
	
/* If you followed the logic behind the duplicates commands above and the review 
of test dates, at this point you should have a fairly good sense of the 
structure of the test data. Now we can begin applying decision rules to simplify 
that structure. 

First, let's deal with the cases where there are multiple scores for a given 
test on the same test date. We could pick a record at random, choose the lowest 
score, or choose the highest score. Because there is not a strong reason to keep 
the lowest score, and keeping a record at random could lead to different results 
with slightly different versions of the dataset, we'll choose to keep the 
highest score in these cases. This decision rule affects a relatively small 
share of the records.

To do this, we'll use the bysort prefix to sort the data by student, school 
year, test ID, date, and score. Because the scale_score variable is in 
parentheses, data will be sorted by score within the student-test-date groups, 
but the score won't be used to define the group. _n refers to the "current" 
record number (Stata iterates through all records automatically, so you can also 
think of it as a "generic" record number). _N refers to the last record number 
of each group, so this command tells Stata to keep only the highest-scoring, or 
last, record in each case of duplicated student, test, and date. */

	bysort sid school_year test_id test_date (scale_score): ///
		keep if _n == _N // 3,083 records dropped
	isid sid school_year test_id test_date
	
/* Now, we'll decide to keep the record from the earliest test date, using 
similar syntax. This decision rule affects a larger number of records. We are 
choosing this decision rule for consistency, so that we are keeping the first 
test date for all students, including those who have only one test date (most of 
the students) and those who have multiple test dates, thus avoiding any 
systematic effects on test scores of having taken more than one test. Here the 
first record of each group is kept. */

	bysort sid school_year test_id (test_date): ///
		keep if _n == 1 // 18,168 records dropped
	isid sid school_year test_id
	
/* Just like that, we now have only one record per student, school year, and 
test ID. Check the distribution of records across school years. The growth 
across school years is more even than before, without the jump in the number of 
test instances in 2009. */

	tab test_id school_year, mi
	
/* We're getting very close to being able to reshape the test score data so that 
there is one record per student and year, with math and reading scores for each 
year. However, we haven't dealt with possible cases where students took more 
than one type of reading or math test (ie, multiple tests for the same subject 
but for different grade levels) in a given year. We also don't know if there are 
any students who took tests for different subjects at different grade levels. To 
help with these last checks and get the data ready for reshaping, parse the test 
ID to define variables for test grade level and test subject. */

	gen test_subject = substr(test_id, 1, 2)
	label var test_subject "Test Subject"
	tab test_subject test_id, mi
	gen test_grade = real(substr(test_id, -1, 1))
	label var test_grade "Test Grade Level"
	tab test_grade test_id, mi
	
/* Check for cases of students taking a test in multiple grades. There is only 
one such case--one student took both 7th and 8th grade math tests along with a 
7th grade reading test. */

	egen numgrade = nvals(test_grade), by(sid school_year)
	tab numgrade, mi
	browse if numgrade == 2
	drop numgrade
	
/* If there were many cases like this, we might want to merge the test data with 
student enrollment data to get the students' actual enrolled grades. However, 
only one record needs to be dropped. Decide to keep the test score for the lower 
grade, since that will lead to the student having the same grade level for 
reading and math. */

	bysort sid school_year test_subject (test_grade): ///
		keep if _n == 1 // 1 record dropped
	
/* At this point we can drop the test ID and test date variables. */

	drop test_id test_date
	
/* Just to verify: for a given student and year, there is now no more than one 
test record per subject. */

	duplicates report sid school_year test_subject
	isid sid school_year test_subject
	
/* Finally, are there any cases of students with math and ELA tests for 
different grade levels? If so, we might need to have separate variables for 
math test grade level and ELA test grade level after reshaping the data, at 
least until the test scores have been standardized by grade and year.
Fortunately there are no such instances. */

	egen numgrade = nvals(test_grade), by(sid school_year)
	assert numgrade == 1
	drop numgrade
	
	
/* RESHAPE DATA */

/* The data is currently in long format, with one record per student, year and 
subject, and one test score per record. We want to convert it to wide format, 
with one record per student and year, but two test score variables, one for each 
subject. This will make it easy to merge the test score dataset later with a 
student dataset that has annual information about student school enrollment, 
demographics, and program participation. We can do this using Stata's reshape 
command.

The logic behind the reshape command is complicated. Most of the Stata commands 
demonstrated in this tutorial will probably start to feel intuitive with 
experience, but it is harder to get the syntax for reshape correct on the 
first try. Before reshaping data, take a few deep breaths, clear your mind of 
distractions, and make sure you have the help page for reshape displayed. */

	help reshape
	
/* Since we're reshaping wide by test subject, the test subject values will 
become suffixes for the variables that vary by test subject. Change the values 
so they will work well as suffixes. */

	replace test_subject = "_e" if test_subject == "RD"
	replace test_subject = "_m" if test_subject == "MA"
	tab test_subject, mi
	
/* Now, do the reshape. This is more or less magic, but it will work. 

--> Browse the data before and after reshaping to make sure you understand how 
		the reshape command changes the structure. */

	reshape wide scale_score ach_level accommodation, i(sid school_year) ///
		j(test_subject, string)
	isid sid school_year
	
/* The data is now unique at the student and year level. Do some tidying up. */

	order sid school_year test_grade scale_score_m scale_score_e ach_level_m ///
		ach_level_e accommodation_m accommodation_e
	label var scale_score_m "Math Scale Score"
	label var scale_score_e "English/Language Arts Scale Score"
	label var ach_level_m "Math Achievement Level"
	label var ach_level_e "English/Language Arts Achievement Level"
	label var accommodation_m "Student Had Math Test Accommodation (Post-2008 only)"
	label var accommodation_e "Student Had ELA Test Accommodation (Post-2008 only)"
	
/* We've made a clean, tidy dataset, and simplified and restructured it the way 
we wanted, but we've ignored the single most important set of values: the actual 
test scores. In real life, you'd probably check the distribution of test scores 
in the raw data long before you started cleaning the dataset. Instead, we've 
saved it here until the end. These commands will generate a set of histograms by 
subject, year, and grade level, and save them to the tables_figures output 
directory. */

	foreach subject in m e {
		histogram scale_score_`subject', by(school_year test_grade) width(1) freq
		graph export "../tables_figures/test_score_distribution_`subject'.png", replace
	}
**check on low outlier ELA 3rd/4th grade scores in 2007 and 2009 ELA test change

/* 
--> Review the histograms.

You can see that the test score distributions aren't all consistent from year to 
year. In particular, you'll notice that the test score range changed for ELA 
tests in 2008, likely signalling a change in the test. A few of the ELA 
grades and years seem to have a handful of low-scoring outliers. There aren't 
any strong ceiling effects, but some of the math tests have some rightward skew, 
and some have a wider and/or more irregular distribution than others. Overall, 
there don't seem to be substantial data errors.

After reviewing the histograms, if you feel reasonably comfortable using the 
scores as measures of student outcomes, you can standardize them by subtracting 
the mean and dividing by the standard deviation for each subject, grade, and 
year. This will convert the test scores to standard deviation units with a mean 
of zero and a standard deviation of one, so that you can compare results for 
different tests. The center command makes this easy, but you may need to install 
it. */

	*ssc install center
	foreach subject in m e {
		bysort school_year test_grade: center scale_score_`subject', ///
			standardize gen(scale_score_std_`subject') 
	}
	order scale_score_std_m scale_score_std_e, after(scale_score_e)
	label var scale_score_std_m "Math Scale Score (Standard deviations)
	label var scale_score_std_e "ELA Scale Score (Standard deviations)
	summ scale_score*, detail
	
	
/* SAVE CLEANED DATA FILE */

/* Finally, save your cleaned test score file. */

	compress
	isid sid school_year
	save "../data/clean/test_scores", replace
	
/* End the do file by closing the log. */

	log close
	
/*
--> Review the log file by choosing "View" from the file menu in the main Stata
		Window. Choose browse, and then click the dropdown arrow to change the file
		type selection from *.smcl (Stata's proprietary mark-up language format) to
		*.log (plain text), and then open and skim through the log file.
	
This tutorial has been a long and discursive walk through the process of 
cleaning a raw test score file. Here's what the do file might look like without 
pedagogical content. Note the blank lines between sections of code and the 
concise, declarative comments. */


/* APPENDIX: COMMENTED CODE */

/* This do file demonstrates cleaning synthetic test score data for the OpenSDP 
Data Janitor tutorial series. It generates a file at the student-year level with 
grade 3-8 math and ELA state assessment scores.

Strategic Data Project
May 2018 */

/*
	// Set up.
	clear all
	capture log close
	set more off
	set type double
	set seed 42
	global logdate: display %tdCCYYNNDD date("$S_DATE","DMY")

	// Open log file.
	log using "../log_files/cleaning_raw_data_$logdate.log", text replace
	
	// Load data.
	use "../data/raw/TEST_2006_2010", clear
	describe
	codebook
	*browse

	// Trim variables.
	foreach var of varlist _all {
		replace `var' = trim(`var')
	}

	// Drop unnecessary variables.
	tab reporting_year, mi
	tab reporting_year collection_code, mi
	tab reporting_year extraction_date, mi
	drop collection_code extraction_date

	// Clean school year.
	tab reporting_year, mi
	destring reporting_year, replace
	rename reporting_year school_year
	label var school_year "School Year"
	
	// Clean and format student ID.
	destring student_id, replace
	assert student_id != .
	rename student_id sid
	label var sid "Student ID"
	format sid %9.0f
	
	// Clean test ID.
	tab test_id, mi sort
	tab test_id school_year, mi
	label var test_id "Test ID"

	// Format test date.
	gen tempdate = date(test_date, "YMD")
	drop test_date
	rename tempdate test_date
	format test_date %td
	label var test_date "Test Date"
	
	// Verify that test dates fall within the correct school years. No 
	// exceptions for math and ELA grades 3-8 tests.
	gen testyear = year(test_date)
	replace testyear = testyear + 1 if month(test_date) > 6
	tab testyear school_year, mi 
	*browse if testyear != school_year
	drop testyear
	
	// Tidy order.
	order sid school_year test_id test_date
	
	// Clean test scores. Check distributions later, after reshaping.
	tab score, mi
	replace score = "" if score == "NS"
	destring score, replace
	rename score scale_score
	label var scale_score "Scale Score"
	
	// Clean achievement level.
	tab ach_level, mi
	tab test_id ach_level, mi row
	destring ach_level, replace
	label var ach_level "Test Achievement Level"
	label define ach_level_lbl 1 "Novice" 2 "Developing" 3 "Proficient" 4 "Advanced"
	label values ach_level ach_level_lbl
	tab ach_level, mi

	// Examine cscore. High correlations with scale score for elementary and 
	// middle school reading and math, some low correlations for other tests. 
	destring cscore*, replace
	codebook cscore*
	summ cscore*, detail
	corr cscore scale_score
	bysort test_id school_year: corr cscore scale_score
	
	// Check problematic and non-problematic test examples. Low correlations 
	// apparently linked to bimodal scale score distributions, possibly due to 
	// different tests with same name.
	scatter scale_score cscore if test_id == "ENGL" | test_id == "ALG1" | ///
		test_id == "RD05", by(test_id school_year)
	hist scale_score if test_id == "ENGL"
	hist cscore if test_id == "ENGL"
	
	// Drop cscore variables, since they have high missingness, and we lack 
	// information about how they were defined.
	drop cscore*
**check on cscore* definitions
	
	// Clean test accommodation status. Missing before 2009.
	tab accommodation, mi
	tab school_year accommodation, mi
	replace accommodation = "1" if accommodation == "Y"
	replace accommodation = "0" if missing(accommodation) & school_year > 2008
	destring accommodation, replace
	label var accommodation "Student Had Test Accommodation (Post-2008 only)"
	
	// Clean fake data indicator. All data is fake, but keep indicator for 
	// reassurance.
	destring fake_data, replace
	assert fake_data == 1
	label var fake_data "Simulated Data Record"
	
	// Drop duplicates and records with missing test scores.
	duplicates report
	duplicates drop // 973 records dropped
	drop if missing(scale_score) // 3042 records dropped
		
	// Check test IDs for grades 3-8 math and ELA.
	tab test_id, sort mi
	tab test_id if substr(test_id, 1, 2) == "MA" | substr(test_id, 1, 2) == "RD", mi
	tab test_id school_year if substr(test_id, 1, 2) == "MA" | ///
		substr(test_id, 1, 2) == "RD", mi
		
	// Check on MA3P and RD3P tests. They occur in September and appear to be 
	// pre-tests.
	gen testmonth = month(test_date)
	foreach test in "RD3P" "RD03" "MA3P" "MA03" {
		display "`test'"
		tab testmonth if test_id == "`test'", mi
	}
	drop testmonth
**verify that MA3P and RD3P are 3rd grade pre-tests
	
	// Restrict to math and reading state test scores for grades 3-8.
	keep if inlist(test_id,"MA03","MA04","MA05","MA06","MA07","MA08") | ///
		inlist(test_id,"RD03","RD04","RD05","RD06","RD07","RD08")
	tab test_id school_year, mi
		
	// Examine data structure. Data is unique at the student-year-test-date-score 
	// level.
	duplicates report sid school_year
	duplicates report sid school_year test_id
	duplicates report sid school_year test_id test_date
	sort sid school_year test_id
	duplicates tag sid school_year test_id test_date, gen(tag)
	*browse if tag
	drop tag
	duplicates report sid school_year test_id test_date scale_score
	isid sid school_year test_id test_date scale_score
	
	// Check number of test dates per test ID.
	egen numdate = nvals(test_date), by(test_id school_year)
	tab numdate, mi
	tab school_year numdate, mi
	drop numdate
	tab test_date test_id, mi
	
	// Keep highest test score for a given test and date.
	bysort sid school_year test_id test_date (scale_score): ///
		keep if _n == _N // 3,083 records dropped
	isid sid school_year test_id test_date
	
	// Keep earliest score for a given test.
	bysort sid school_year test_id (test_date): ///
		keep if _n == 1 // 18,168 records dropped
	isid sid school_year test_id
	
	// Distribution across years looks good.
	tab test_id school_year, mi
	
	// Parse test ID to get subject and grade level.
	gen test_subject = substr(test_id, 1, 2)
	label var test_subject "Test Subject"
	tab test_subject test_id, mi
	gen test_grade = real(substr(test_id, -1, 1))
	label var test_grade "Test Grade Level"
	tab test_grade test_id, mi
	
	// Resolve single case of tests in multiple grades.
	egen numgrade = nvals(test_grade), by(sid school_year)
	tab numgrade, mi
	*browse if numgrade == 2
	drop numgrade
	bysort sid school_year test_subject (test_grade): ///
		keep if _n == 1 // 1 record dropped
	
	// Drop test ID and date.
	drop test_id test_date
	
	// Verify structure; one record per student, year, and subject.
	duplicates report sid school_year test_subject
	isid sid school_year test_subject
	
	// Check for students taking ELA and math in different grades. No cases.
	egen numgrade = nvals(test_grade), by(sid school_year)
	assert numgrade == 1
	drop numgrade
	
	// Reshape data wide to have one record per student and year.
	replace test_subject = "_e" if test_subject == "RD"
	replace test_subject = "_m" if test_subject == "MA"
	tab test_subject, mi
	reshape wide scale_score ach_level accommodation, i(sid school_year) ///
		j(test_subject, string)
	isid sid school_year
	
	// Tidy up.
	order sid school_year test_grade scale_score_m scale_score_e ach_level_m ///
		ach_level_e accommodation_m accommodation_e
	label var scale_score_m "Math Scale Score"
	label var scale_score_e "English/Language Arts Scale Score"
	label var ach_level_m "Math Achievement Level"
	label var ach_level_e "English/Language Arts Achievement Level"
	label var accommodation_m "Student Had Math Test Accommodation (Post-2008 only)"
	label var accommodation_e "Student Had ELA Test Accommodation (Post-2008 only)"
	
	// Check distribution of scaled test scores by subject, year and grade.
	foreach subject in m e {
		histogram scale_score_`subject', by(school_year test_grade) width(1) freq
		graph export "../tables_figures/test_score_distribution_`subject'.png", replace
	}
**check on low outlier ELA 3rd/4th scores in 2007 and 2008 ELA test change
	
	// Define standardized test score variables.
	foreach subject in m e {
		bysort school_year test_grade: center scale_score_`subject', ///
			standardize gen(scale_score_std_`subject') 
	}
	order scale_score_std_m scale_score_std_e, after(scale_score_e)
	label var scale_score_std_m "Math Scale Score (Standard deviations)
	label var scale_score_std_e "ELA Scale Score (Standard deviations)
	summ scale_score*, detail
	
	// Save clean test score file.
	compress
	isid sid school_year
	save "../data/clean/test_scores", replace
	
	log close
	
