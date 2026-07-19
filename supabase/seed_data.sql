-- ExamPrep seed content. Run AFTER schema.sql. Safe to re-run (clears first).
delete from notes where uploader_id is null;
delete from topics where created_by is null;

insert into notes (course_id,uploader_name,title,chapter,exam_type,text_body,rating_sum,rating_count) values
('nust-cs-s3-cs201','Ayesha K.','Complete DSA Handwritten Notes','All Chapters','finalExam','',22,5),
('nust-cs-s3-cs201','Bilal R.','Trees & Graphs Cheat Sheet','Trees, Graphs','midterm','Binary trees, BST, AVL rotations, BFS vs DFS, Dijkstra shortest path. Focus on traversal orders and rotation cases.',18,4),
('nust-cs-s3-cs201','Hamza T.','Sorting Algorithms Summary','Sorting','quiz','Merge sort, quick sort, heap sort — time complexities and stability.',12,3),
('nust-cs-s3-cs203','Sana M.','SQL & Normalization Notes','Normalization, SQL','finalExam','1NF to BCNF with examples, joins, subqueries, and transaction ACID properties.',19,4),
('lums-cs-s4-cs204','Zohaib A.','Dynamic Programming Patterns','DP','finalExam','Knapsack, LCS, matrix chain, coin change. Recurrence + memoization templates.',24,5),
('fast-cs-s4-cs205','Fatima S.','OS Scheduling & Deadlocks','Scheduling, Deadlocks','midterm','FCFS, SJF, Round Robin, priority scheduling. Banker''s algorithm worked example.',14,3),
('bahria-cs-s2-csc210','Usman Q.','OOP Concepts & UML','Inheritance, Polymorphism','midterm','Encapsulation, inheritance, polymorphism, abstraction. Class vs object, UML class diagrams, and overriding vs overloading.',17,4),
('bahria-cs-s4-csc220','Hira N.','DBMS Final Prep','SQL, Normalization','finalExam','ER-to-relational mapping, normalization up to BCNF, SQL joins and aggregate queries.',20,4);

insert into topics (course_id,name,times_appeared,total_votes) values
('nust-cs-s3-cs201','Binary Trees & BST',5,5),
('nust-cs-s3-cs201','Graph Traversal (BFS/DFS)',4,5),
('nust-cs-s3-cs201','Sorting Algorithms',3,5),
('nust-cs-s3-cs201','Hashing',2,5),
('nust-cs-s3-cs201','Linked Lists',2,5),
('nust-cs-s3-cs201','Dynamic Programming',1,5),
('nust-cs-s3-cs203','Normalization (1NF-BCNF)',5,6),
('nust-cs-s3-cs203','SQL Joins & Subqueries',4,6),
('nust-cs-s3-cs203','Transactions & ACID',3,6),
('nust-cs-s3-cs203','ER Diagrams',2,6),
('lums-cs-s4-cs204','Dynamic Programming',5,5),
('lums-cs-s4-cs204','Greedy Algorithms',3,5),
('lums-cs-s4-cs204','Graph Algorithms',4,5),
('lums-cs-s4-cs204','NP-Completeness',2,5),
('fast-cs-s4-cs205','CPU Scheduling',5,6),
('fast-cs-s4-cs205','Deadlocks',4,6),
('fast-cs-s4-cs205','Memory Management',3,6),
('fast-cs-s4-cs205','Process Synchronization',3,6),
('nust-cs-s1-cs102','Loops & Conditionals',4,4),
('nust-cs-s1-cs102','Functions & Recursion',3,4),
('nust-cs-s1-cs102','Arrays & Strings',3,4),
('pu-math-s3-math202','Matrix Operations',4,4),
('pu-math-s3-math202','Eigenvalues & Eigenvectors',3,4),
('pu-math-s3-math202','Vector Spaces',2,4),
('bahria-cs-s2-csc210','Inheritance & Polymorphism',5,5),
('bahria-cs-s2-csc210','Encapsulation & Abstraction',3,5),
('bahria-cs-s2-csc210','Exception Handling',2,5),
('bahria-cs-s2-csc210','UML Class Diagrams',2,5),
('bahria-cs-s4-csc220','Normalization',5,6),
('bahria-cs-s4-csc220','SQL Queries',4,6),
('bahria-cs-s4-csc220','ER Modeling',3,6);
