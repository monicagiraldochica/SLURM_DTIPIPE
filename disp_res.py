#!/usr/bin/env python3
__author__ = "Monica Keith"
__status__ = "Production"

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import collections
import networkx as nx
from networkx.algorithms import community
from PIL import Image
import os
import sys
from operator import itemgetter
import datetime

def printout(string,fout):
    print(string)
    fout.write(string+'\n')

def removeHeaders(fipath,fopath):
    fin = open(fipath,'r')
    fout = open(fopath,'w')
    
    i = 0
    for line in fin:
        if i>0:
            array = line.split(',')
            line = line.replace(array[0]+',','')
            fout.write(line)
        else:
            labels = line[1:].replace('\n','').replace('_','').split(',')
        i+=1
    
    fout.close()
    fin.close()
    
    return labels

def thrRSmatrices(pmat,rmat,outfolder):
    N = len(pmat)
    Ppos = np.zeros(shape=(N,N))
    Pneg = np.zeros(shape=(N,N))
    ppout = open(outfolder+"/pmat_num_pos.csv",'w')
    pnout = open(outfolder+"/pmat_num_neg.csv",'w')
    for i in range(N):
        for j in range(N):
            pval = pmat[i,j]
            rval = rmat[i,j]
            # threshold out non-significant values
            if pval<=0.05 and rval!=0:
                # save pvalue for positive correlations
                if rval>0:
                    ppout.write(str(pval))
                    Ppos[i,j] = pval
                    # set negative to zero
                    Pneg[i,j] = 0
                    pnout.write('0')
                # save pvalue for negative correlations
                else:
                    pnout.write(str(pval))
                    Pneg[i,j] = pval
                    # set positive to zero
                    Ppos[i,j] = 0
                    ppout.write('0')
            else:
                Ppos[i,j] = 0
                Pneg[i,j] = 0
                ppout.write('0')
                pnout.write('0')
            if j<N-1:
                ppout.write(',')
                pnout.write(',')
        ppout.write('\n')
        pnout.write('\n')
    
    print(Ppos)
    pnout.close()
    ppout.close()
    return Ppos,Pneg

def groupRSmatrix(M,outpath):
    N = len(M)
    W = np.zeros(shape=(N,N))
    fout = open(outpath,'w')
    for i in range(N):
        for j in range(N):
            val = M[i,j]
            if val==0:
                W[i,j] = 0
                fout.write('0')
            elif val<=0.01:
                W[i,j] = 2
                fout.write('2')
            elif val<=0.05:
                W[i,j] = 1
                fout.write('1')
            else:
                W[i,j] = 0
                fout.write('0')
            if j<N-1:
                fout.write(',')
        fout.write('\n')
                
    fout.close()
    return W
    
def RSgraphs(log_path,sbj_path,sbjID,sessID):
    fout = open(log_path,'a')
    printout("\n**RS**",fout)
    
    # Create a version without heathers for the pmat and rmat
    # remove first line and first column
    printout("Removing heathers...",fout)
    labels = removeHeaders(sbj_path+"/pmat.csv",sbj_path+"/pmat_num.csv")
    removeHeaders(sbj_path+"/rmat.csv",sbj_path+"/rmat_num.csv")
    if (not os.path.isfile(sbj_path+"/pmat_num.csv")) or (not os.path.isfile(sbj_path+"/rmat_num.csv")):
        sys.exit("error removing heathers")
    printout("done:",fout)
    printout(sbj_path+"/pmat_num.csv",fout)
    printout(sbj_path+"/rmat_num.csv",fout)
    
    # Load the numerical matrices
    printout("\nLoading matrices...",fout)
    P = np.loadtxt(open(sbj_path+"/pmat_num.csv","rb"), delimiter=",").astype(float)
    R = np.loadtxt(open(sbj_path+"/rmat_num.csv","rb"), delimiter=",").astype(float)
    printout("done",fout)
    
    # Remove the non-significant correlations (threshold), separate the negative from the positive
    printout("\nThresholding matrices...",fout)
    [Ppos, Pneg] = thrRSmatrices(P,R,sbj_path)
    if (not os.path.isfile(sbj_path+"/pmat_num_pos.csv")) or (not os.path.isfile(sbj_path+"/pmat_num_neg.csv")):
        sys.exit("error thresholding matrices")
    printout("done:",fout)
    printout(sbj_path+"/pmat_num_pos.csv",fout)
    printout(sbj_path+"/pmat_num_neg.csv",fout)

    # I am not plotting the thresholded p-matrices because lower values are less visible than higher. If I don't invert the colors then values 0 are not white.
    # There can be pottential solutions but that matrix is not used since the important one is the grouped one for RS, so it's not necessary to visualize it
    # Difference with DSI is that higher values are better and we want to see them darker. But here lower p-values are better
    
    # Generate weighted matrices and graph (grouped)
    printout("\nGenerating weighted matrices..",fout)
    PWpos = groupRSmatrix(Ppos,sbj_path+"/pmat_num_pos_group.csv")
    PWneg = groupRSmatrix(Pneg,sbj_path+"/pmat_num_neg_group.csv")
    if (not os.path.isfile(sbj_path+"/pmat_num_pos_group.csv")) or (not os.path.isfile(sbj_path+"/pmat_num_neg_group.csv")):
        sys.exit("error generating weighted matrices")
    printout("done:",fout)
    printout(sbj_path+"/pmat_num_pos_group.csv",fout)
    printout(sbj_path+"/pmat_num_neg_group.csv",fout)
    
    # Plot the wighted p-matrices
    printout("\nPlotting weighted matrices...",fout)
    connPlots(PWpos,labels,sbj_path+"/pmat_num_pos_group.png",sbjID+'_'+sessID)
    connPlots(PWneg,labels,sbj_path+"/pmat_num_neg_group.png",sbjID+'_'+sessID)
    if (not os.path.isfile(sbj_path+"/pmat_num_pos_group.png")) or (not os.path.isfile(sbj_path+"/pmat_num_neg_group.png")):
        sys.exit("error plotting weighted matrices")
    printout("done:",fout)
    printout(sbj_path+"/pmat_num_pos_group.png",fout)
    printout(sbj_path+"/pmat_num_neg_group.png",fout)
    
    # Generate weighted graphs
    printout("\nCreating positive weighted graph...",fout)
    graphFile(PWpos,sbj_path+"/pmat_num_pos_group_graph.csv")
    netgraph(PWpos,sbj_path+"/pmat_num_pos_group_graph.csv",labels,sbj_path+"/pmat_num_pos_group_graph.png",fout,sbj_path,"rs")
    if not os.path.isfile(sbj_path+"/pmat_num_pos_group_graph.csv"):
        sys.exit("error creating positive weighted graph")
    printout("done:",fout)
    printout(sbj_path+"/pmat_num_pos_group_graph.csv",fout)
    printout(sbj_path+"/pmat_num_pos_group_graph.png",fout)
    
    printout("\nCreating negative weighted graph...",fout)
    graphFile(PWneg,sbj_path+"/pmat_num_neg_group_graph.csv")
    netgraph(PWneg,sbj_path+"/pmat_num_neg_group_graph.csv",labels,sbj_path+"/pmat_num_neg_group_graph.png",fout,sbj_path,"rs")
    if not os.path.isfile(sbj_path+"/pmat_num_neg_group_graph.csv"):
        sys.exit("error creating negative weighted graph")
    printout("done:",fout)
    printout(sbj_path+"/pmat_num_neg_group_graph.csv",fout)
    printout(sbj_path+"/pmat_num_neg_group_graph.png",fout)
    fout.close()

    # Calculate graph metrics for the positive and negative graph
    fout = open(log_path,'a')
    printout("\nCalculating graph metrics for positive graph...",fout)
    graphMetrics(sbj_path+"/pmat_num_pos_group_graph.csv",labels,fout,sbjID,sessID,"pos")
    printout("done",fout)
    fout.close()
    
    fout = open(log_path,'a')
    printout("\nCalculating graph metrics for negative graph...",fout)
    graphMetrics(sbj_path+"/pmat_num_neg_group_graph.csv",labels,fout,sbjID,sessID,"neg")
    printout("done",fout)
    fout.close()

def graphMetrics(graphfile,axlabels,fout,sbj_id,sess_id,gtype):
    data3 = pd.read_csv(graphfile)
    
    # Get the list of connectivity values
    connectedness = []
    for val in data3.iloc[:,2]:
        connectedness+=[int(round(val))]
    
    # Get the list of starting roi
    roi1 = []
    for roi in data3.iloc[:,0]:
        roi1+=[axlabels[roi]]
    
    # Get the list of end roi
    roi2 = []
    for roi in data3.iloc[:,1]:
        roi2+=[axlabels[roi]]
    
    # Print the network metrics for the weighted graph
    df = pd.DataFrame({ 'from':roi1, 'to':roi2, 'value':connectedness})
    G = nx.from_pandas_edgelist(df, 'from', 'to', edge_attr=True, create_using=nx.Graph())
    printout(nx.info(G),fout)
    
    # Measures of functional segregation
    transitivity = str(nx.transitivity(G))
    printout("Transitivity: "+transitivity,fout)
    communities_generator = community.girvan_newman(G)
    next(communities_generator) #top_level_communities
    next_level_communities = next(communities_generator)
    printout("Modular structure (Newman algorithm)",fout)
    modules = sorted(map(sorted, next_level_communities))
    i = 0
    modstr = ''
    for module in modules:
        printout("Module "+str(i)+':',fout)
        cnt = '['
        for node in module:
            cnt+=str(node)+','
        cnt = cnt[:-1]+']'
        printout(cnt,fout)
        modstr+=cnt
        if i<len(modules)-1:
            modstr+=','
        i+=1
    printout("modular_structure: "+modstr,fout)
    modularity = str(community.quality.modularity(G,next_level_communities))
    printout("Modularity: "+modularity,fout)
    
    if nx.is_connected(G):
        # Measures of functional integration
        printout("Characteristic path length: "+str(nx.average_shortest_path_length(G)),fout)
    
        # Small-world coefficient (sigma) of the given graph
        # A graph is commonly classified as small-world if sigma>1
        sig = nx.algorithms.smallworld.sigma(G)
        prefix = ''
        if gtype!="dsi":
            prefix = gtype+'_'
        printout(prefix+"sigma: "+str(sig),fout)
        if sig > 1:
            printout(prefix+"small_world: 1",fout)
        else:
            printout(prefix+"small_world: 0",fout)
        
        # Small-world coefficient (omega) of the given graph
        # Between -1 and 1. Closer to 0, has small world characteristics
        # Closer to -1 G has a lattice shape
        # Closer to 1 G is a random graph
        omega = str(nx.algorithms.smallworld.omega(G))
        printout(prefix+"omega: "+omega,fout)
    else:
        printout("Can't calculate characteristic path length nor small worldness measures (Graph is disconnected)",fout)
        
    # Measures that quantify centrality of individual brain regions or pathways
    printout("Top 10% nodes by degree:",fout)
    degree_dic = dict(G.degree(G.nodes()))
    nx.set_node_attributes(G, degree_dic, 'degree')
    sort_degree = sorted(degree_dic.items(), key=itemgetter(1), reverse=True)
    p = 10*len(sort_degree)/100
    top_degree = ''
    for node,degree in sort_degree[:int(p)]:
        printout("* "+node+": "+str(degree)+" connections",fout)
        top_degree+=node+','
    top_degree = top_degree[:-1]
    # Eigenvector centrality
    # Is a node a hub and is it conencted to many hubs
    # Between 0 and 1, closer to 1 greater centrality
    # Which nodes can get information to any other nodes quickly
    printout("Top 10% nodes by centrality:",fout)
    eigenvector_dic = nx.eigenvector_centrality(G)
    nx.set_node_attributes(G, eigenvector_dic, 'eigenvector')
    sort_centrality = sorted(eigenvector_dic.items(), key=itemgetter(1), reverse=True)
    top_centrality = ''
    for node,centrality in sort_centrality[:int(p)]:
        printout("* "+node+": "+str(centrality)+" centrality",fout)
        top_centrality+=node+','
    top_centrality = top_centrality[:-1]
    
    # Network density gives a quick sense of how closely knit the network is
    # Ratio of actual edges to all possible edges in the network
    # From 0 to 1. Closer to 1 is more dense.
    density = str(nx.density(G))
    printout("Density: "+density,fout)
    
    # Measures that test resilience of networks to insult
    printout("Calculating the degree histogram...",fout)
    degree_sequence = sorted([d for n, d in G.degree()], reverse=True)
    degreeCount = collections.Counter(degree_sequence)
    deg, cnt = zip(*degreeCount.items())
    fig, ax = plt.subplots()
    plt.bar(deg, cnt, width=0.80, color="b")
    plt.title("Degree Histogram")
    plt.ylabel("Count")
    plt.xlabel("Degree")
    ax.set_xticks([d + 0.4 for d in deg])
    ax.set_xticklabels(deg)
    plt.savefig(graphfile.replace(".csv","_dist.png"), dpi=150)
    plt.close()
    printout("done: "+graphfile.replace(".csv","_dist.png"),fout)
    r = nx.degree_assortativity_coefficient(G)
    printout("Assortativity: "+str(r),fout)
    # Networks with positive assortativity: have a resilient core of mutually inter-connected high-degree hubs. 
    # Networks with negative assortativity: have widely distributed and vulnerable high-degree hubs.
    if r>0:
        printout("Positive assortativity, probably resilient: "+str(r),fout)
    elif r<0:
        printout("Negative assortativity, probably vulnerable: "+str(r),fout)
    else:
        printout("Assortativity 0. Cant tell if its resilient",fout)
            
def mergeHorizontalImgs(imgsList,output,rmorigs):
    imgs1 = [Image.open(i) for i in imgsList]
    min_img_height1 = min(i.height for i in imgs1)
    
    # Re-size images if necessary
    total_width1 = 0
    for i, img in enumerate(imgs1):
        # If the image is larger than the minimum height, resize it
        if img.height > min_img_height1:
            imgs1[i] = img.resize((min_img_height1, int(img.height / img.width * min_img_height1)), Image.ANTIALIAS)
        total_width1 += imgs1[i].width
    img_merge1 = Image.new(imgs1[0].mode, (total_width1, min_img_height1))
    
    # Concatenate horizontally
    x = 0
    for img in imgs1:
        img_merge1.paste(img, (x, 0))
        x += img.width
    
    img_merge1.save(output)
    if rmorigs:
        for img in imgsList:
            os.remove(img)

def mergeVerticalImgs(imgsList,output,rmorigs):
    imgs = [Image.open(i) for i in imgsList]
    min_img_width = min(i.width for i in imgs)
    
    # Re-size images if necessary
    total_height = 0
    for i, img in enumerate(imgs):
        # If the image is larger than the minimum width, resize it
        if int(img.height / img.width * min_img_width)>0 and img.width>min_img_width:
            imgs[i] = img.resize((min_img_width, int(img.height / img.width * min_img_width)), Image.ANTIALIAS)
        total_height += imgs[i].height
    img_merge = Image.new(imgs[0].mode, (min_img_width, total_height))
    
    # Concatenate vertically
    y = 0
    for img in imgs:
        img_merge.paste(img, (0, y))
        y += img.height
    
    img_merge.save(output)
    if rmorigs:
        for img in imgsList:
            os.remove(img)

def getConnections(roi_index,df):
    df1 = df[df['roi1'] == roi_index]
    c = []
    if not df1.empty:
        a = df1.iloc[:,1]
        for e in np.array(a):
            c+=[e]
            
    df2 = df[df['roi2'] == roi_index]
    if not df2.empty:
        b = df2.iloc[:,0]
        for e in np.array(b):
            c+=[e]
            
    return c

def addROI(roi_index,df,list1,axlabels,list2):
    # list2 will be the list of roi that are connected (a graph cluster)
    list2+=[axlabels[roi_index]]
    # Get the list of roi that are connected to roi_index
    roi_connections = getConnections(roi_index,df)
    list1.remove(roi_index)
    # Call recursively the function for each connected roi
    for conn in roi_connections:
        if conn in list1:
            list1 = addROI(conn,df,list1,axlabels,list2)
    return list1

def getClusterGroups(roi1,roi2,axlabels,df):
    groups = {}
    
    # Get the indices of all roi that have connections
    # Because in the df they appear with their index instead of roi name
    list1 = []
    for roi in np.unique(np.array(roi1+roi2)):
        list1+=[axlabels.index(roi)]
    
    # Group the roi in clusters where all the items are connected
    list2 = []
    while len(list1)>0:
        list1 = addROI(list1[0],df,list1,axlabels,list2)
        groups["Cluster "+str(len(groups.keys())+1)] = list2
        list2 = []
    
    return groups

def netgraph(M,graphfile,axlabels,pngout,fout,sbjpath,pipe):
    data3 = pd.read_csv(graphfile)
   
    # Get the list of connectivity values
    connectedness = []
    for val in data3.iloc[:,2]:
        connectedness+=[int(round(val))]
    
    # Get the list of starting roi
    roi1 = []
    for roi in data3.iloc[:,0]:
        roi1+=[axlabels[roi]]
    
    # Get the list of end roi
    roi2 = []
    for roi in data3.iloc[:,1]:
        roi2+=[axlabels[roi]]
    
    # Obtain the different clusters of connected roi
    groups = getClusterGroups(roi1,roi2,axlabels,data3)
    clusters = sorted(groups.keys())
    
    # For each graph cluster get the list of nodes (roi1 and roi2) and their edge value (conn)
    grp_roi1 = {}
    grp_roi2 = {}
    grp_conn = {}
    for i in range(len(connectedness)):
        a = roi1[i]
        b = roi2[i]
        c = connectedness[i]
        for clust in clusters:
            # If the two roi belong to clust
            # The two should belong to the same cluster if grouped correctly
            if (a in groups[clust]) and (b in groups[clust]):
                if clust in grp_roi1.keys():
                    grp_roi1[clust]+=[a]  
                else: 
                    grp_roi1[clust] = [a]
                if clust in grp_roi2.keys():
                    grp_roi2[clust]+=[b]
                else:
                    grp_roi2[clust] = [b]
                if clust in grp_conn.keys():
                    grp_conn[clust]+=[c]  
                else:
                    grp_conn[clust] = [c]
    
    # Graph each cluster in a separate image
    # https://matplotlib.org/stable/tutorials/colors/colormaps.html
    cmap = plt.cm.winter
    
    # Get the number of hubs (subplots)
    # Get the number of lines and columns in the plot
    n_grps = len(grp_conn)
    printout("# of subgraphs: "+str(n_grps),fout)
    if n_grps % 5 == 0:
        n_cols = 5
    elif n_grps % 4 == 0:
        n_cols = 4
    elif n_grps % 3 == 0:
        n_cols = 3
    elif n_grps % 2 == 0:
        n_cols = 2
    else:
        n_cols = 1
    printout("Grouping in "+str(n_cols)+" columns",fout)
    n_lines = int(n_grps/n_cols)
    printout("and "+str(n_lines)+" lines",fout)
    test_imgs = []
    tmp_imgs = []
    
    if pipe=="rs":
        x_dim = 30
        y_dim = 15
    else:
        x_dim = 10
        y_dim = 15
    
    for i in range(n_grps):
        print("Creating subplot "+str(i+1)+" of "+str(n_grps))
        plt.subplots(figsize=(x_dim, y_dim))
        clust = clusters[i]
        df = pd.DataFrame({ 'from':grp_roi1[clust], 'to':grp_roi2[clust], 'value':grp_conn[clust]})
        G = nx.from_pandas_edgelist(df, 'from', 'to', edge_attr=True, create_using=nx.Graph())
        nx.draw(G, with_labels=True, node_color='skyblue', node_size=1400, edge_color=df['value'], edge_cmap=cmap)
        plt.savefig(sbjpath+"/test"+str(i)+".png", dpi=150)
        plt.close()
        if not os.path.isfile(sbjpath+"/test"+str(i)+".png"):
            sys.exit("subplot was not created")
            
        # Merge the images to create a final PDF
        test_imgs+=[sbjpath+"/test"+str(i)+".png"]
        # Merge images horizontally
        if len(test_imgs)==n_cols:
            if n_lines==1:
                mergeHorizontalImgs(test_imgs,pngout,True)
            else:
                mergeHorizontalImgs(test_imgs,sbjpath+"/tmp"+str(len(tmp_imgs))+".png",True)
                if not os.path.isfile(sbjpath+"/tmp"+str(len(tmp_imgs))):
                    sys.exit("images were not merged horizontally")
                tmp_imgs+=[sbjpath+"/tmp"+str(len(tmp_imgs))+".png"]
            test_imgs = []
        # Merge horizontal images vertically as lines
        if len(tmp_imgs)==n_lines and n_lines>1:
            mergeVerticalImgs(tmp_imgs,pngout,True)
            if not os.path.isfile(pngout):
                sys.exit("images were not merged vertically")

def graphFile(C,graphfile):   
    dim = len(C)
    fout = open(graphfile,'w')
    fout.write("roi1,roi2,conn\n")
    for i in range(dim):
        for j in range(i+1,dim):
            if C[i,j]>0:
                fout.write(str(i)+','+str(j)+','+str(C[i,j])+'\n')
    fout.close()

def connPlots(C,axlabels,pngout,figtit):
    # General plot properties
    plt.figure(figsize=(15, 10))
    dim = len(C)
    plt.xticks(range(dim), axlabels, rotation='vertical')
    plt.yticks(range(dim), axlabels)
    plt.grid(True, linestyle=':')
    plt.title(figtit, fontsize=24)
    
    # Colormap properties
    # https://matplotlib.org/stable/tutorials/colors/colormaps.html
    plt.imshow(C,cmap='gist_heat_r')
    
    plt.savefig(pngout, dpi=150)
    plt.close()

def connectedness(M,outfile):
    dim = len(M)
    C = np.zeros(shape=(dim,dim))
    for i in range(dim):
        for j in range(i+1,dim):
            avg = np.mean([M[i,j],M[j,i]])
            C[i,j] = avg
            C[j,i] = avg
    
    out = open(outfile,'w')
    for i in range(dim):
        for j in range(dim):
            out.write(str(C[i,j]))
            if j<dim-1:
                out.write(',')
        out.write('\n')
    out.close()
    
    return C

def DSIgraphs(log_path,sbj_path,sbj_id,sess_id):
    fout = open(log_path,'a')
    printout("\n**DSI**",fout)
    
    # Load the connectivity matrix: contains just the values, no heather
    # One line per ROI, one column per ROI, values are connectivity
    printout("Loading connectivity matrix...",fout)
    M = np.loadtxt(open(sbj_path+"/matrix.csv","rb"), delimiter=",").astype(int)
    printout("done",fout)
    
    # Get the axes labels
    printout("\nGetting axes labels...",fout)
    k = open(sbj_path+"/tracto.csv",'r')
    axlabels = k.readline()[1:].replace('\n','').replace('_','').split(',')
    k.close()
    printout("done",fout)
    
    # Create connectedness matrix
    printout("\nCreating connectedness matrix...",fout)
    C = connectedness(M,sbj_path+"/connectedness.csv")
    if not os.path.isfile(sbj_path+"/connectedness.csv"):
        sys.exit("error creating connectedness matrix")
    printout("done: "+sbj_path+"/connectedness.csv",fout)
    
    # Plot the connectedness matrix
    printout("\nCreating the connectedness matrix plot...",fout)
    connPlots(C,axlabels,sbj_path+"/connectedness.png",sbj_id+'_'+sess_id)
    if not os.path.isfile(sbj_path+"/connectedness.png"):
        sys.exit("error creating connectedness matrix plot")
    printout("done: "+sbj_path+"/connectedness.png",fout)
    
    # Generate weighted graph
    printout("\nCreating weighted graph...",fout)
    graphFile(C,sbj_path+"/connectedness_graph.csv")
    netgraph(C,sbj_path+"/connectedness_graph.csv",axlabels,sbj_path+"/connectedness_graph.png",fout,sbj_path,"dsi")
    if not os.path.isfile(sbj_path+"/connectedness_graph.png"):
        sys.exit("error creating weighted graph")
    printout("done: "+sbj_path+"/connectedness_graph.png",fout)
    fout.close()

    # Calculate the graph metrics
    fout = open(log_path,'a')
    printout("\nCalculating graph metrics...",fout)
    graphMetrics(sbj_path+"/connectedness_graph.csv",axlabels,fout,sbj_id,sess_id,"dsi")
    printout("done",fout)
    fout.close()
    
def main():
    t1_date = str(datetime.date.today().strftime("%Y_%m_%d"))
    t1_time = str(datetime.datetime.today().strftime("%H:%M:%S"))
    t1_dt = t1_date+'_'+t1_time
                
    # python3 disp_res.py --sbj=KML --sess=day1 --pipe=rs --location=hpc
    # python3 disp_res.py --sbj=KML --sess=day1 --pipe=dsi
    sbj_id = ''
    sess_id = ''
    pipeline = ''
    sbj_path = ''
    log_path = ''
    location = ''
    for arg in sys.argv:
        if arg.startswith("--sbj="):
            sbj_id = arg.replace("--sbj=",'').upper()
        elif arg.startswith("--sess="):
            sess_id = arg.replace("--sess=",'').lower()
        elif arg.startswith("--pipe="):
            pipeline = arg.replace("--pipe=",'').lower()
        elif arg.startswith("--sbj_path="):
            sbj_path = arg.replace("--sbj_path=",'')
        elif arg.startswith("--log_path="):
            log_path = arg.replace("--log_path=",'')
        elif arg.startswith("--location="):
            location = arg.replace("--location=",'')
            
    if sbj_id=='' or sess_id=='' or pipeline=='' or sbj_path=='' or location=='' or log_path=='':
        sys.exit("Missing arguments")
    fout = open(log_path,'w')
    printout("Processing "+sbj_id+'_'+sess_id+' '+pipeline,fout)
    printout("Output folder: "+sbj_path,fout)
    printout("Log file: "+log_path,fout)
    printout("Location: "+location,fout)
    fout.close()

    if pipeline=="rs":
        RSgraphs(log_path,sbj_path,sbj_id,sess_id)
    elif pipeline=="dsi":
        DSIgraphs(log_path,sbj_path,sbj_id,sess_id)
    else:
        sys.exit("Wrong pipeline")
    
    t2_date = str(datetime.date.today().strftime("%Y_%m_%d"))
    t2_time = str(datetime.datetime.today().strftime("%H:%M:%S"))
    t2_dt = t2_date+'_'+t2_time
    tdelta = str(datetime.datetime.strptime(t2_dt,"%Y_%m_%d_%H:%M:%S") - datetime.datetime.strptime(t1_dt,"%Y_%m_%d_%H:%M:%S"))
    fout = open(log_path,'a')
    printout("Execution time: "+tdelta,fout)   
    fout.close()

if __name__ == "__main__":
        main()
