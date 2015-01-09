# SANN
Scheme Artificial Neural Network v0.1

Copyright (C) 2014-5  Sam Findler

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


Why another Neural Network Module?

This program is a simple neural network module that I have implemented in the Scheme Programming Language.  Currently it only supports backpropogated neural networks, however, with the macro operation "make-net/n" arbitrarily complex neural network structures can be created wihtout having to manually enter in every aspect of the configuration.  

Further, with the macro "ngo/4," the neuralnetwork can be trained with arbitrarily large datasets, which it normalizes, gradually stepping down the expected Mean Square Error to improve its ability to recognize patterns and feeding in a final input to the trained neural network which can be used to test the predictive capability of the net against future data.  

The "ngo/4" macro currently also does slight error checking to attempt to ensure that the neural network configuration will converge, a feature which will be improved in future versions.  However, even without the modifications since it is almost fully automated in the construction and training of neural networks, this module  could prove valuable in implementing in production software, where other manually constructed neural networks could be less viable.

Additionaly, since this module was built with a heavy emphasis on modularity, it is a relatively simple thing to customize it to your specifications.  For example, changing the error checking from MSE to RMS should involve the modification of just one function (the function that actually calculates the MSE).  Also, since the ngo macro is separate from the functions that actually train the neural network, it is easy enough to ignore the automatic training features altogether and train your neural network manually.


Future Features

I am currently working on a file parser to coinside with the program that will take various kinds of well formated files (tab delimited, csv, txt) and extrapolate a training-set of input output values, because for now all of the data must be manually input, which is a frustrating and time consuming process.  

I also plan to add supports for other kinds of neural networks, and an operation that will produce connections that are not simply random, but have a distribution that edges closer to .5.

Additionally, as the project grows, I plan to add a lot more error checking to make the automation of training neural networks a much more pain free process.


Contact

If you find any errors or have suggestions for improvements, you may email me at 23rdSchemer@gmail.com


How to use the Module

Since the program is just one file, it should be simple enough to load it into your program.  Simply use the nonstandard procedure load:  (load "{your file location}/net.scm").  Any r6rS compliant Scheme should be able to use the module.  Currently, MIT-GNU Scheme does not support brackets, so it will not work in MIT-GNU scheme, however, if you simply go through the module and switch out the brackets for parentheses it should work.

The source file contains a description of all of the functions.  However, for those that don't want to wade through the couple hundred lines of code, here is a brief description of the two most useful functions:

make-net:  make-net takes n arguments and returns a neural network data structure of n layers with randomized connections and all nodes initialized to zero.  For example, (make-net 2 4 2) will create a neural network with a 2 node input layer, a 2 node output layer and a 4 node hidden layer.  The actual data structure will look like this:
    #('(#(0 0) #(0 0 0 0) #(0 0)) ((#(...) #(...) #(...) #(...)) (#(... ...) #(... ...)))),
    where the elipses are each two random numbers between 0 and 1.

ngo:  takes 4 arguments, a training-set, a neural network data structure, an ideal-MSE and a final input-vecotr. The training-set should be a list containing two lists, a list-of-inputs and a list-of-outputs.  These lists should be the same length, and each input / output should match the input / output nodes of the neural network.  e.g. 
'((#(24 543) #(123 435)) (#(234 342) #( 1234))) could be a training-set for a neural network made with (make-net 2 4 2).  Keep in mind that this macro takes non-normalized training-sets and final inputs and normalizes them, so don't use values between 0 and 1 with ngo (use run-net instead).

note1:  Since update 1, "ngo" uses two functions: "run-normalized" and "dno" (denormalized-output).  These can be split up and increase the usefulness of the program

run-normalized is useful if you want to save a neural net for future updates and outputs:
For example:
for some training-set and network, we could declare 
(define network_2 (run-normalized (car training-set) (cadr training-set) network ideal-MSE))
then later call (run-normalized (car training-set-2) (cadr training-set-2) network_2 ideal-MSE) and train the net some more

We can then combine run-normalized with dno and get a sort of delayed and reusable ngo
for example if we run (dno network_2 input) for some input, it would be as if we initially ran
(ngo training-set network ideal-MSE input), but it can be useful to split these processes up and to be able to save a trained neural network

as always, see the source code for further documentation


note2:  be sure to play close attention to what the program is doing with the four global variables, you may very well want to modify these depending on the way you are implementing the neural network.


