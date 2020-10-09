function [Cv,Cell,SharedFaces]=BuildCells(TT,Y,X,xInternal,xExternal,H)
nC=length(xInternal);
Cell = CellClass(X,nC,xInternal,xExternal);

% -------
TetIDs=1:size(TT,1);
%% Initiate global database
Cv=zeros(Cell.n*16*8,2);
count0=1; % counter for the number of vertex-bar Elemets 

Cell.SurfsCenters=zeros(size(X,1)*4,3); % the posiion of Cell-surface centers
SharedFaces = FacesClass(size(X,1)*4);
count1=1; % counter for the number of SurfsCenters / faces; 
count2=0; % counter for total number of SurfsTris 

Includedx=false(size(Cell.Int,2),1);
%% Build Interior Cells
for i=1:length(Cell.Int) % loop over  Interior cells
    Includedx(i)=true;
    % i Should be Cell.Int(i) when boundary nodes are included
    
    % ----- Build Tet
%     Cell.cTris{i}=[];
    Cell.cTet{i}=TT(any(ismember(TT,Cell.Int(i)),2),:);
    Cell.cTetID{i}=TetIDs(any(ismember(TT,Cell.Int(i)),2));
    Cell.cNodes{i}=unique(Cell.cTet{i}); 
    Cell.cNodes{i}(Cell.cNodes{i}==Cell.Int(i))=[];
    
    % ----- Build Surfaces and Trinagles   
    %-- Initiate cellular database
%    Cell.CellSurfsCentersID{i}=zeros(length(Cell.cNodes{i}),1);
    nS=length(Cell.cNodes{i});
    Cell.Surfaces{i}.nSurfaces=nS;
    Cell.Surfaces{i}.SurfaceCentersID=zeros(nS,1);
    Cell.Surfaces{i}.SurfaceVertices=cell(nS,1);
    Cell.Surfaces{i}.Tris=cell(nS,1);

    Cell.Tris{i}=zeros(120,3);
    count3=1;  % counter for cellular-number of SurfsTris   
    Cell.Cv{i}=zeros(16*8,2);
    count4=1;  % counter for cellular-number of vertex-bars  
    
    for j=1:length(Cell.cNodes{i}) % loop over cell-Surfaces
        
        SurfAxes=[Cell.Int(i) Cell.cNodes{i}(j)];                               % line crossing the surface
        SurfTet=Cell.cTet{i}(sum(ismember(Cell.cTet{i},SurfAxes),2)==2,:);      
        SurfTetID=Cell.cTetID{i}(sum(ismember(Cell.cTet{i},SurfAxes),2)==2);
        
        %--- Order Surface Vertices\Tets as loop 
        SurfVertices=zeros(length(SurfTetID),1);   
        AuxSurfTet=SurfTet; 
        AuxSurfTetID=SurfTetID; % To be arranged
        % Take the first 
        SurfVertices(1)=SurfTetID(1);
        AuxSurfTet(1,:)=[];
        AuxSurfTetID(1)=[];
        % Take the nearby regardless of the direction
        NextVertexlogic=sum(ismember(AuxSurfTet,SurfTet(1,:)),2)==3;
        aux1=1:length(NextVertexlogic); aux1=aux1(NextVertexlogic);
        SurfVertices(2)=AuxSurfTetID(aux1(1));
        %remove the Found
        aux2=AuxSurfTet(aux1(1),:);
        AuxSurfTet(aux1(1),:)=[];
        AuxSurfTetID(aux1(1))=[];
        for k=3:length(SurfVertices) %loop over Surf-vertices
            % Find the next, as the one who share three nodes with previous
            NextVertexlogic=sum(ismember(AuxSurfTet,aux2),2)==3;
            SurfVertices(k)=AuxSurfTetID(NextVertexlogic);
            %remove the Found
            aux2=AuxSurfTet(NextVertexlogic,:);
            AuxSurfTet(NextVertexlogic,:)=[];
            AuxSurfTetID(NextVertexlogic)=[];
        end 
        
        % build the center of the face (interpolation)
          
         % check if the center i already built
         oppNode=Cell.Int==SurfAxes(2); 
         if Includedx(oppNode)
             cID=Cell.Surfaces{oppNode}.SurfaceCentersID(Cell.cNodes{oppNode}==SurfAxes(1));
             aux2=cID;
             aux=Cell.SurfsCenters(aux2,:);
         else 
             aux=sum(Y.DataRow(SurfVertices,:),1)/length(SurfVertices);
             if sum(ismember(SurfAxes,Cell.Int))==1
                 dir=(aux-X(Cell.Int(i),:)); dir=dir/norm(dir);
                 aux=X(Cell.Int(i),:)+H.*dir;
             end
              aux2=count1;
         end 
         
         
         
        % check  Orientation
%         v1=Y.DataRow(SurfVertices(1),:)-aux;
%         v2=Y.DataRow(SurfVertices(2),:)-aux;
        if i==5
            malik=1;
        end 
            
        Order=0;
        for iii=1:length(SurfVertices)
            if iii==length(SurfVertices)
                v1=Y.DataRow(SurfVertices(iii),:)-aux;
                v2=Y.DataRow(SurfVertices(1),:)-aux;
                Order=Order+dot(cross(v1,v2),aux-X(Cell.Int(i),:))/length(SurfVertices);
            else 
                v1=Y.DataRow(SurfVertices(iii),:)-aux;
                v2=Y.DataRow(SurfVertices(iii+1),:)-aux;
                Order=Order+dot(cross(v1,v2),aux-X(Cell.Int(i),:))/length(SurfVertices);
            end 
        end 
        if Order<0
           SurfVertices=flip(SurfVertices);
        end 
        
        % Save surface vertices 
        Cell.Surfaces{i}.SurfaceVertices{j}=SurfVertices;
        
         % Build Tringles and CellCv
         % Build Tringles and CellCv
         if length(SurfVertices)==3 % && false
             Cell.Tris{i}(count3,:)=[SurfVertices(1) SurfVertices(2) -SurfVertices(3)];
             Cell.Surfaces{i}.Tris{j}=[SurfVertices(1) SurfVertices(2) -SurfVertices(3)];
             auxCv=[SurfVertices(1) SurfVertices(2);
                           SurfVertices(2) SurfVertices(3);
                           SurfVertices(3) SurfVertices(1)];
             count2=count2+1;
             count3=count3+1;
             
             auxCv(ismember(auxCv,Cell.Cv{i},'rows') | ismember(flip(auxCv,2),Cell.Cv{i},'rows'),:)=[];
             Cell.Cv{i}(count4:count4+size(auxCv,1)-1,:)=auxCv;
             count4=count4+size(auxCv,1);
             
            % save Surface-center
             if Includedx(oppNode)
                 Cell.Surfaces{i}.SurfaceCentersID(j)=cID;
             else 
                 Cell.SurfsCenters(count1,:)=aux;
                 Cell.Surfaces{i}.SurfaceCentersID(j)=count1;
                 % Save Face-data base 
                  SharedFaces = SharedFaces.Add(SurfAxes,SurfVertices,Y.DataOrdered,Cell.SurfsCenters);
                 count1=count1+1;
             end 
         else 
             auxCv=zeros(length(SurfVertices),2);
             Cell.Surfaces{i}.Tris{j}=zeros(length(SurfVertices),3);
             for h=2:length(SurfVertices)
                Cell.Tris{i}(count3,:)=[SurfVertices(h-1) SurfVertices(h) aux2];
                Cell.Surfaces{i}.Tris{j}(h-1,:)=[SurfVertices(h-1) SurfVertices(h) aux2];
                auxCv(h-1,:)=[SurfVertices(h-1) SurfVertices(h)];
                count2=count2+1;
                count3=count3+1;
             end 
             Cell.Tris{i}(count3,:)=[SurfVertices(end) SurfVertices(1) aux2];
             Cell.Surfaces{i}.Tris{j}(h,:)=[SurfVertices(end) SurfVertices(1) aux2];

             auxCv(h,:)=[SurfVertices(end) SurfVertices(1)];
             % remove do duplicated bars
             auxCv(ismember(auxCv,Cell.Cv{i},'rows') | ismember(flip(auxCv,2),Cell.Cv{i},'rows'),:)=[];
             Cell.Cv{i}(count4:count4+size(auxCv,1)-1,:)=auxCv;
             count2=count2+1;
             count3=count3+1;
             count4=count4+size(auxCv,1);
              % save Surface-center
             if Includedx(oppNode)
                 Cell.Surfaces{i}.SurfaceCentersID(j)=cID;
             else 
                 Cell.SurfsCenters(count1,:)=aux;
                 Cell.Surfaces{i}.SurfaceCentersID(j)=count1;
                 % Save Face-data base 
                  SharedFaces = SharedFaces.Add(SurfAxes,SurfVertices,Y.DataOrdered,Cell.SurfsCenters);
                 count1=count1+1;
             end 
         end 

         

    end 
    Cell.Tris{i}(count3:end,:)=[];
    Cell.Cv{i}(count4:end,:)=[];
    
    Cell.CvID{i}=count0:count0+size(Cell.Cv{i},1)-1;
    Cv(count0:count0+size(Cell.Cv{i},1)-1,:)=Cell.Cv{i};
    count0=count0+size(Cell.Cv{i},1);
end 
Cell.SurfsCenters(count1:end,:)=[];
Cv(count0:end,:)=[];
Cell.nTotalTris=count2;



%% change type of data strucutre (should be done in the beginning)

aux=Cell.SurfsCenters;
Cell.SurfsCenters=DynamicArray(size(X,1)*8,3);
Cell.SurfsCenters=Cell.SurfsCenters.Add(aux);
[Cell]=BuildEdges(Cell,Y);
%% Compute Cells volume 
[Cell]=ComputeCellVolume(Cell,Y);
Cell.Vol0=Cell.Vol;
Cell.SArea0=Cell.SArea;
for i=1:Cell.n
%     Cell.SAreaTri0{i}=Cell.SAreaTri{i}*1e-2;
    Cell.SAreaTri0{i}=ones(size(Cell.SAreaTri{i}))*1e-3;
%     Cell.SAreaTri0{i}=Cell.SAreaTri{i};

end 
Cell.SAreaFace0=Cell.SAreaFace;

SharedFaces=SharedFaces.ComputeAreaTri(Y.DataRow,Cell.SurfsCenters.DataRow);


end 



%%



