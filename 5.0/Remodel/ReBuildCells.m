function [Cell,Faces,nC,SCn,flag32]=ReBuildCells(Cell,T,Y,X,Faces,SCn)

TetIDs=1:size(T.DataRow,1);
nC=[];
flag32=false;
for i=1:length(Cell.Int) % loop over  Interior cells
    if ~ismember(Cell.Int(i),Cell.AssembleNodes)
        continue 
    end 
    % Copy the old thing 
    Copy_cNodes=Cell.cNodes{i};
    Copy_Surface=Cell.Surfaces{i};
    Cell.nTotalTris=Cell.nTotalTris-size(Cell.Tris{i},1);
    
    % ----- Build Tet
    Cell.cTet{i}=T.DataRow(any(ismember(T.DataRow,Cell.Int(i)),2),:);        % should be improved 
    Cell.cTetID{i}=TetIDs(any(ismember(T.DataRow,Cell.Int(i)),2));   % should be improved 
    Cell.cNodes{i}=unique(Cell.cTet{i}); 
    Cell.cNodes{i}(Cell.cNodes{i}==Cell.Int(i))=[];
    
    %-- Initiate cellular database
    nS=length(Cell.cNodes{i});
    Cell.Surfaces{i}.nSurfaces=nS;
    Cell.Surfaces{i}.SurfaceCentersID=zeros(nS,1);
    Cell.Surfaces{i}.SurfaceVertices=cell(nS,1);
    Cell.Surfaces{i}.Tris=cell(nS,1);
    Cell.Tris{i}=zeros(120,3);
    count3=1;  % counter for cellular-number of SurfsTris   
    Cell.Cv{i}=zeros(16*8,2);
    count4=1;  % counter for cellular-number of vertex-bars  
    
    % ----- Build Surfaces and Trinagles  
    for j=1:length(Cell.cNodes{i}) % loop over cell-Surfaces
        
        SurfAxes=[Cell.Int(i) Cell.cNodes{i}(j)];                               % line crossing the surface
        SurfTet=Cell.cTet{i}(sum(ismember(Cell.cTet{i},SurfAxes),2)==2,:);      
        SurfTetID=Cell.cTetID{i}(sum(ismember(Cell.cTet{i},SurfAxes),2)==2);
        
    %------Order Surface Vertices\Tets as loop 
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
        if length(aux1)<1
            flag32=true;
            return
        end 
        SurfVertices(2)=AuxSurfTetID(aux1(1));
        %remove the Found
        aux2=AuxSurfTet(aux1(1),:);
        AuxSurfTet(aux1(1),:)=[];
        AuxSurfTetID(aux1(1))=[];
        for k=3:length(SurfVertices) %loop over Surf-vertices
            % Find the next, as the one who share three nodes with previous
            NextVertexlogic=sum(ismember(AuxSurfTet,aux2),2)==3;
            if length(AuxSurfTetID(NextVertexlogic))~=1
                flag32=true;
                return
            end 
            SurfVertices(k)=AuxSurfTetID(NextVertexlogic);
            %remove the Found
            aux2=AuxSurfTet(NextVertexlogic,:);
            AuxSurfTet(NextVertexlogic,:)=[];
            AuxSurfTetID(NextVertexlogic)=[];
        end 
        if sum(ismember(SurfVertices,[7 149 198]))==3
            malik=1;
        end 
        
     %---build the center of the face (interpolation)
         % look for the center ID in the previuos strucutre 
         % (by cheking the corresponding Nodal connevtiiy )
         aux2=Copy_Surface.SurfaceCentersID(Copy_cNodes==SurfAxes(2)); 
         aux3=[];
         if isempty(aux2) && ~isempty(nC)
            % if it is not found check if it is already added by another cell 
              for nf=1:length(nC)
                 if all(ismember(SurfAxes,Faces.Nodes(nC(nf),:)))
                    aux2=nC(nf); 
                    aux3=Faces.Vertices{aux2};
                 end 
              end
         elseif ~isempty(aux2)
            aux3=Copy_Surface.SurfaceVertices{Copy_cNodes==SurfAxes(2)};
         end 
         if ~isempty(aux2)
             if length(aux3)==3 
                 aux=sum(Y.DataRow(SurfVertices,:),1)/length(SurfVertices);
             else 
                 aux=Cell.SurfsCenters.DataRow(aux2,:);
             end 
         else 
             % Center/Face is not there !! Add it !!
            aux=sum(Y.DataRow(SurfVertices,:),1)/length(SurfVertices);
%              if sum(ismember(SurfAxes,Cell.Int))==1
%                  dir=(aux-X(Cell.Int(i),:)); dir=dir/norm(dir);
%                  H=1.5/2;
%                  aux=X(Cell.Int(i),:)+H.*dir;
%              end

         end 

        % check  Orientation
%         v1=Y.DataRow(SurfVertices(1),:)-aux;
%         v2=Y.DataRow(SurfVertices(2),:)-aux;
%         if dot(cross(v1,v2),aux-X(Cell.Int(i),:))<0
%            SurfVertices=flip(SurfVertices);
%         end 
        Order=0;
        aux4=sum(Y.DataRow(SurfVertices,:),1)/length(SurfVertices);
        for iii=1:length(SurfVertices)
            if iii==length(SurfVertices)
                v1=Y.DataRow(SurfVertices(iii),:)-aux4;
                v2=Y.DataRow(SurfVertices(1),:)-aux4;
                Order=Order+dot(cross(v1,v2),aux4-X(Cell.Int(i),:))/length(SurfVertices);
            else
                v1=Y.DataRow(SurfVertices(iii),:)-aux4;
                v2=Y.DataRow(SurfVertices(iii+1),:)-aux4;
                Order=Order+dot(cross(v1,v2),aux4-X(Cell.Int(i),:))/length(SurfVertices);
            end
        end
        if Order<0
            SurfVertices=flip(SurfVertices);
        end
        
        
        
        
        
        % save face-data 
        if ~isempty(aux2)
            Faces.Vertices{aux2}=SurfVertices;
            if length(SurfVertices)==3
                Faces.V3(aux2)=true;
                Faces.V4(aux2)=false;
            elseif length(SurfVertices)==4
                Faces.V3(aux2)=false;
                Faces.V4(aux2)=true;
            else 
                Faces.V3(aux2)=false;
                Faces.V4(aux2)=false;
            end 
             Cell.SurfsCenters.DataRow(aux2,:)=aux;
        else 
            [Cell.SurfsCenters,nCC]=Cell.SurfsCenters.Add(aux);
            nC=[nC nCC]; %#ok<AGROW>
            SCn=SCn.Add(aux);
            [Faces,aux2]=Faces.Add(SurfAxes,SurfVertices,Y.DataRow,Cell.SurfsCenters.DataRow);
        end 
        
        % Save surface vertices 
        Cell.Surfaces{i}.SurfaceVertices{j}=SurfVertices;
        if length(SurfVertices)==3
             Cell.Tris{i}(count3,:)=[SurfVertices(1) SurfVertices(2) -SurfVertices(3)];
             Cell.Surfaces{i}.Tris{j}=[SurfVertices(1) SurfVertices(2) -SurfVertices(3)];
             auxCv=[SurfVertices(1) SurfVertices(2);
                           SurfVertices(2) SurfVertices(3);
                           SurfVertices(3) SurfVertices(1)];
             count3=count3+1;
             
             auxCv(ismember(auxCv,Cell.Cv{i},'rows') | ismember(flip(auxCv,2),Cell.Cv{i},'rows'),:)=[];
             Cell.Cv{i}(count4:count4+size(auxCv,1)-1,:)=auxCv;
             count4=count4+size(auxCv,1);
             
             % save Surface-center
            Cell.Surfaces{i}.SurfaceCentersID(j)=aux2;
        else
             % Build Tringles and CellCv
             auxCv=zeros(length(SurfVertices),2);
             Cell.Surfaces{i}.Tris{j}=zeros(length(SurfVertices),3);
             for h=2:length(SurfVertices)
                Cell.Tris{i}(count3,:)=[SurfVertices(h-1) SurfVertices(h) aux2];
                Cell.Surfaces{i}.Tris{j}(h-1,:)=[SurfVertices(h-1) SurfVertices(h) aux2];
                auxCv(h-1,:)=[SurfVertices(h-1) SurfVertices(h)];
    %             Cell.Cv{i}(count4)=
                count3=count3+1;
             end 
             Cell.Tris{i}(count3,:)=[SurfVertices(end) SurfVertices(1) aux2];
             Cell.Surfaces{i}.Tris{j}(h,:)=[SurfVertices(end) SurfVertices(1) aux2];

             auxCv(h,:)=[SurfVertices(end) SurfVertices(1)];
             % remove do duplicated bars
             auxCv(ismember(auxCv,Cell.Cv{i},'rows') | ismember(flip(auxCv,2),Cell.Cv{i},'rows'),:)=[];
             Cell.Cv{i}(count4:count4+size(auxCv,1)-1,:)=auxCv;
    %          count2=count2+1;
             count3=count3+1;
             count4=count4+size(auxCv,1);


            % save Surface-center
            Cell.Surfaces{i}.SurfaceCentersID(j)=aux2;
            
        end
        

    end 
    Cell.Tris{i}(count3:end,:)=[];
    Cell.Cv{i}(count4:end,:)=[];
    Cell.nTotalTris=Cell.nTotalTris+size(Cell.Tris{i},1);

    % This bit need to be corrected 
%     Cell.CvID{i}=count0:count0+size(Cell.Cv{i},1)-1;
%     Cv(count0:count0+size(Cell.Cv{i},1)-1,:)=Cell.Cv{i};
%     count0=count0+size(Cell.Cv{i},1);
end


for i=1:length(Cell.Ext) % loop over  Interior cells
    Cell.cTet{i}=T.DataRow(any(ismember(T.DataRow,Cell.Ext(i)),2),:);        % should be improved 
    if ~ismember(Cell.Ext(i),Cell.AssembleNodes)
        continue 
    end 
end  
[Cell]=BuildEdges(Cell,Y);

% Total number

% Area and volume 

end 
