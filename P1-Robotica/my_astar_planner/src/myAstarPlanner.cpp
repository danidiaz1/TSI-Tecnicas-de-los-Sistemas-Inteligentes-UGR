/*********************************************************************
*
* Software License Agreement (BSD License)
*
*  Copyright (c) 2008, Willow Garage, Inc.
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions
*  are met:
*
*   * Redistributions of source code must retain the above copyright
*     notice, this list of conditions and the following disclaimer.
*   * Redistributions in binary form must reproduce the above
*     copyright notice, this list of conditions and the following
*     disclaimer in the documentation and/or other materials provided
*     with the distribution.
*   * Neither the name of Willow Garage, Inc. nor the names of its
*     contributors may be used to endorse or promote products derived
*     from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
*  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
*  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
*  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
*  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
*  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
*  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
*  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
*  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
*  POSSIBILITY OF SUCH DAMAGE.
*
* Authors: Eitan Marder-Eppstein, Sachin Chitta
*********************************************************************/
#include "../include/my_astar_planner/myAstarPlanner.h"
#include <pluginlib/class_list_macros.h>
#include <math.h>
#include <chrono>

//para pintar puntos
#include <visualization_msgs/Marker.h>

// para debugging
#include <sstream>
#include <string>


//register this planner as a BaseGlobalPlanner plugin
PLUGINLIB_EXPORT_CLASS(myastar_planner::MyastarPlanner, nav_core::BaseGlobalPlanner)

namespace myastar_planner {

  list<coupleOfCells>::iterator getPositionInList(list<coupleOfCells> & list1, unsigned int cellID);
  bool isContains(set<coupleOfCells, comparator> & set1, int cellID);

  MyastarPlanner::MyastarPlanner()
  : costmap_ros_(NULL), initialized_(false){}

  MyastarPlanner::MyastarPlanner(std::string name, costmap_2d::Costmap2DROS* costmap_ros)
  : costmap_ros_(NULL), initialized_(false){
    initialize(name, costmap_ros);
  }

  void MyastarPlanner::initialize(std::string name, costmap_2d::Costmap2DROS* costmap_ros){
    if(!initialized_){
      costmap_ros_ = costmap_ros;
      costmap_ = costmap_ros_->getCostmap();
      footprint_= costmap_ros_->getRobotFootprint();
      costmap_2d::calculateMinAndMaxDistances(footprint_,footprint_radius_min_, footprint_radius_max_);
      cell_size = costmap_->getResolution();
      //ROS_INFO("resolucion = %f", cell_size);
      distancia_vecino = ceil(footprint_radius_min_ / cell_size);

      ros::NodeHandle private_nh("~/" + name);

      //vamos a asumir estos parámetros, que no es necesario enviar desde el launch.
      private_nh.param("step_size", step_size_, costmap_->getResolution());
      private_nh.param("min_dist_from_robot", min_dist_from_robot_, 0.10);
      //world_model_ = new base_local_planner::CostmapModel(*costmap_);

      //el plan se va a publicar en el topic "planTotal"
      plan_pub_ = private_nh.advertise<nav_msgs::Path>("planTotal",1);
      //los puntos del espacio de búsqueda se visualizan en "visualization_marker"
      marker_Open_publisher = private_nh.advertise<visualization_msgs::Marker>("open_list", 1000);
      marker_Closed_publisher = private_nh.advertise<visualization_msgs::Marker>("closed_list", 1000);
      marker_Goals_publisher = private_nh.advertise<visualization_msgs::Marker>("goals_markers", 1000);


      initialized_ = true;
    }
    else
      ROS_WARN("This planner has already been initialized... doing nothing");
  }

  //we need to take the footprint of the robot into account when we calculate cost to obstacles
  double MyastarPlanner::footprintCost(double x_i, double y_i){
    if(!initialized_){
      ROS_ERROR("The planner has not been initialized, please call initialize() to use the planner");
      return -1.0;
    }

    vector<unsigned int> vecinos;
    double valoracion = 0;
    unsigned int m_x, m_y;

    int dist_minima_footprint = trunc(footprint_radius_min_/cell_size);
    //ROS_INFO("dist_maxima_footprint = %d", dist_maxima_footprint);

    for (int dist = 1; dist <= dist_minima_footprint; dist+=2){
      //ROS_INFO("casilla = (%f,%f) dist = %d", x_i,y_i,dist);
      vecinos = findNeighborCell2(costmap_->getIndex(x_i, y_i), dist, 255);

      vector<unsigned int>::iterator it;

      for (it = vecinos.begin(); it != vecinos.end(); ++it){

        costmap_->indexToCells(*it, m_x, m_y);
        unsigned int coste = costmap_->getCost(m_x, m_y);
        valoracion+=coste;
      }
    }

    return valoracion;
  }


  bool MyastarPlanner::makePlan(const geometry_msgs::PoseStamped& start,
      const geometry_msgs::PoseStamped& goal, std::vector<geometry_msgs::PoseStamped>& plan){

    //***********************************************************
    // Inicio de gestion de ROS
    //***********************************************************
    if(!initialized_){
      ROS_ERROR("The astar planner has not been initialized, please call initialize() to use the planner");
      return false;
    }

    ROS_DEBUG("MyastarPlanner: Got a start: %.2f, %.2f, and a goal: %.2f, %.2f", start.pose.position.x, start.pose.position.y, goal.pose.position.x, goal.pose.position.y);

    plan.clear();
    closedList.clear();
    openList.clear();

    //obtenemos el costmap global  que está publicado por move_base.
    costmap_ = costmap_ros_->getCostmap();


    //Obligamos a que el marco de coordenadas del goal enviado y del costmap sea el mismo.
    //esto es importante para evitar errores de transformaciones de coordenadas.
    if(goal.header.frame_id != costmap_ros_->getGlobalFrameID()){
      ROS_ERROR("This planner as configured will only accept goals in the %s frame, but a goal was sent in the %s frame.",
          costmap_ros_->getGlobalFrameID().c_str(), goal.header.frame_id.c_str());
      return false;
    }

    tf::Stamped<tf::Pose> goal_tf;
    tf::Stamped<tf::Pose> start_tf;

    poseStampedMsgToTF(goal,goal_tf);
    poseStampedMsgToTF(start,start_tf);

    //obtenemos la orientación start y goal en start_yaw y goal_yaw.
    double useless_pitch, useless_roll, goal_yaw, start_yaw;
    start_tf.getBasis().getEulerYPR(start_yaw, useless_pitch, useless_roll);
    goal_tf.getBasis().getEulerYPR(goal_yaw, useless_pitch, useless_roll);


    /**************************************************************************/
    /*************** HASTA AQUÍ GESTIÓN DE ROS *********************************/
    /****************************************************************************/

    //pasamos el goal y start a estructura coupleOfCells
    coupleOfCells cpstart, cpgoal;
    double goal_x = goal.pose.position.x;
    double goal_y = goal.pose.position.y;
    unsigned int mgoal_x, mgoal_y;
    costmap_->worldToMap(goal_x,goal_y,mgoal_x, mgoal_y);
    cpgoal.index = MyastarPlanner::costmap_->getIndex(mgoal_x, mgoal_y);
    cpgoal.parent=0;
    cpgoal.gCost=0;
    cpgoal.hCost=0;
    cpgoal.fCost=0;

    double start_x = start.pose.position.x;
    double start_y = start.pose.position.y;
    unsigned int mstart_x, mstart_y;
    costmap_->worldToMap(start_x,start_y, mstart_x, mstart_y);
    cpstart.index = MyastarPlanner::costmap_->getIndex(mstart_x, mstart_y);
    cpstart.parent =cpstart.index;
    cpstart.gCost = 0;
    cpstart.hCost = MyastarPlanner::calculateHCost(cpstart.index,cpgoal.index);
    cpstart.fCost = cpstart.gCost+cpstart.hCost;

    //insertamos la casilla inicial en abiertos
    MyastarPlanner::openList.insert(cpstart);
    //ROS_INFO("Inserto en Abiertos: %d", cpstart.index );
    //ROS_INFO("Index del goal: %d", cpgoal.index );




    /**************************************************************************/
    /*************** GESTIÓN VISUALIZACIÓN PUNTOS DE ABIERTOS Y CERRADOS********/
    /****************************************************************************/

    //visualization_msgs::Marker points;// definida en la clase como markers_OpenList
    inicializaMarkersPoints(markers_OpenList,"openList", 0,0.0f,1.0f,0.0f);
    inicializaMarkersPoints(markers_ClosedList,"closedList", 1,1.0f,0.0f,0.0f);
    inicializaMarkersLine_List(markers_Goals, "goals", 2, 0.0f, 0.0f,1.0f);

    limpiaMarkers(marker_Open_publisher, markers_ClosedList);
    limpiaMarkers(marker_Closed_publisher, markers_OpenList);




    /**************************************************************************/
    /*************** FIN GESTIÓN VISUALIZACIÓN PUNTOS DE ABIERTOS Y CERRADOS********/
    /****************************************************************************/


    //visualizamos start.
    visualizaCelda(marker_Open_publisher, markers_OpenList, cpstart.index);

    auto inicio = std::chrono::high_resolution_clock::now();
    unsigned int explorados = 0;
    unsigned int currentIndex;
    coupleOfCells currentNode;

    while (!MyastarPlanner::openList.empty()) //while the open list is not empty continuie the search
    {

        //escoger un nodo de abiertos
        currentNode = *(openList.begin());
        openList.erase(openList.begin());
        currentIndex = currentNode.index;

        //insertamos el nodo escogido en cerrados
        closedList.insert(pair<unsigned int, coupleOfCells>(currentNode.index, currentNode));

        visualizaCelda(marker_Closed_publisher, markers_ClosedList, currentNode.index);

        // if the currentCell is the goalCell: success: path found

        if(estaContenida(currentIndex, cpgoal.index, ceil(distancia_vecino/2)+1)/*currentIndex==cpgoal.index*/)
        {
            //el plan lo construimos partiendo del goal, del parent del goal y saltando en cerrados "de parent en parent"
            //vamos insertando al final los waypoints (los nodos de cerrados), por tanto, cuando finaliza el bucle hay que darle la vuelta al plan
             //ROS_INFO("Se han explorado %u nodos y cerrados tiene %u nodos", explorados, (unsigned int)closedList.size());
              //ros::Duration(10).sleep();
              //convertimos goal a poseStamped nueva
              geometry_msgs::PoseStamped pose;
              pose.header.stamp =  ros::Time::now();
              pose.header.frame_id = goal.header.frame_id;//debe tener el mismo frame que el de la entrada
              pose.pose.position.x = goal_x;
              pose.pose.position.y = goal_y;
              pose.pose.position.z = 0.0;
              pose.pose.orientation.x = 0.0;
              pose.pose.orientation.y = 0.0;
              pose.pose.orientation.z = 0.0;
              pose.pose.orientation.w = 1.0;

              //lo añadimos al plan
              plan.push_back(pose);

              unsigned int currentParent = currentNode.parent;
              //ROS_INFO("Inserta en Plan GOAL: %f, %f PADRE: %u", pose.pose.position.x, pose.pose.position.y, currentParent);
              //ros::Duration(1).sleep();

              while (currentParent != cpstart.index) //e.d. mientras no lleguemos al nodo start
              {
                //encontramos la posición de currentParent en cerrados
                unordered_map<unsigned int, coupleOfCells>::iterator it=closedList.find(currentParent);

                //hacemos esa posición que sea el currentCouple
                coupleOfCells currentCouple;
                currentCouple.index=currentParent;
                currentCouple.parent=(*it).second.parent;
                currentCouple.gCost=(*it).second.gCost;
                currentCouple.hCost=(*it).second.hCost;
                currentCouple.fCost=(*it).second.fCost;



                //creamos una PoseStamped con la informaciuón de currentCouple.index

                        //primero hay que convertir el currentCouple.index a world coordinates
                unsigned int mpose_x, mpose_y;
                double wpose_x, wpose_y;

                costmap_->indexToCells((*it).second.index, mpose_x, mpose_y);
                costmap_->mapToWorld(mpose_x, mpose_y, wpose_x, wpose_y);

                //ROS_INFO("Las coordenadas de El PADRE de %u son (%u, %u) -> (%f, %f). Y su PADRE es %u.", currentParent, mpose_x,mpose_y,wpose_x, wpose_y, (*it).second.parent);
                //ros::Duration(1).sleep();

                        //después creamos la pose
                geometry_msgs::PoseStamped pose;
                pose.header.stamp =  ros::Time::now();
                pose.header.frame_id = goal.header.frame_id;//debe tener el mismo frame que el de la entrada
                pose.pose.position.x = wpose_x;
                pose.pose.position.y = wpose_y;
                pose.pose.position.z = 0.0;
                pose.pose.orientation.x = 0.0;
                pose.pose.orientation.y = 0.0;
                pose.pose.orientation.z = 0.0;
                pose.pose.orientation.w = 1.0;
                //insertamos la pose en el plan
                plan.push_back(pose);
                //ROS_INFO("Inserta en Plan: %f, %f", pose.pose.position.x, pose.pose.position.y);
                //hacemos que currentParent sea el parent de currentCouple
                currentParent = (*it).second.parent;
              }


            std::reverse(plan.begin(),plan.end());

            //lo publica en el topic "planTotal"
            //publishPlan(plan);
            auto fin = std::chrono::high_resolution_clock::now();
            ROS_INFO("Sale del bucle de generación del plan. Tiempo tardado: %f microsegundos. Longitud del plan: %lu. Nodos explorados: %d",
              double(std::chrono::duration_cast<std::chrono::microseconds>(fin - inicio).count()),
              plan.size(), explorados
            );

            return true;
          }


          //search the neighbors of the current Cell
          vector <unsigned int> neighborCells=findNeighborCell1(currentIndex, distancia_vecino, 200);
          //ROS_INFO("Ha encontrado %u vecinos", (unsigned int)neighborCells.size());

          //neighbors that exist in the closedList are ignored
          vector <unsigned int> neighborNotInClosedList;
          for(vector <unsigned int>::iterator it=neighborCells.begin(); it != neighborCells.end(); ++it)
            if(closedList.find(*it) == closedList.end()) //!isContains(closedList,neighborCells[i])
              neighborNotInClosedList.push_back(*it);

          //ROS_INFO("Ha encontrado %u vecinos que no están en cerrados", (unsigned int)neighborNotInClosedList.size());


          //search the neighbors that already exist in the open List
          vector <unsigned int> neighborsInOpenList;
          vector <unsigned int> neighborsNotInOpenList;
          for(vector<unsigned int>::iterator it = neighborNotInClosedList.begin();
            it != neighborNotInClosedList.end(); ++it)
          {
            if(!isContains(openList,*it))
              //neighborsInOpenList.push_back(neighborNotInClosedList[i]);
            //else
              neighborsNotInOpenList.push_back(*it);
          }


         //add the neighbors that are not in the closed list to the open list and mark the current cell as their parent
        addNeighborCellsToOpenList(openList, neighborsNotInOpenList, currentIndex, currentNode.gCost, cpgoal.index, cpstart.hCost); //,tBreak);


         explorados++;

         //PINTO ABIERTOS
         //Anyadir neighborCells a points. pushback()
         visualizaLista(marker_Open_publisher, markers_OpenList, neighborsNotInOpenList);
         visualizaCelda(marker_Closed_publisher,markers_ClosedList, currentNode.index);


          //Para los nodos que ya están en abiertos, comprobar en cerrados su coste y actualizarlo si fuera necesario

    }

    if(openList.empty())  // if the openList is empty: then failure to find a path
        {
            ROS_INFO("Failure to find a path !");
            return false;
           // exit(1);
        }

};


//calculamos H como la distancia euclídea hasta el goal
double MyastarPlanner::calculateHCost(unsigned int start, unsigned int goal) {
  unsigned int mstart_x, mstart_y, mgoal_x, mgoal_y;
  double wstart_x, wstart_y, wgoal_x, wgoal_y;

  //trasformamos el indice de celdas a coordenadas del mundo.
  //ver http://docs.ros.org/indigo/api/costmap_2d/html/classcostmap__2d_1_1Costmap2D.html

  costmap_->indexToCells(start, mstart_x, mstart_y);
  costmap_->mapToWorld(mstart_x, mstart_y, wstart_x, wstart_y);
  costmap_->indexToCells(goal, mgoal_x, mgoal_y);
  costmap_->mapToWorld(mgoal_x, mgoal_y, wgoal_x, wgoal_y);

  return sqrt((pow(wstart_x - wgoal_x,2))+pow(wstart_y - wgoal_y, 2));
 }


 /*******************************************************************************/
 /* Encuentra vecinos x de la casilla c con coste < cost de la siguiente manera:

  ____________________________
 |___|___|___|___|___|___|___|
 |___|_x_|___|_x_|___|_x_|___|
 |___|___|___|___|___|___|___|
 |___|_x_|___|_c_|___|_x_|___|
 |___|___|___|___|___|___|___|
 |___|_x_|___|_x_|___|_x_|___|
 |___|___|___|___|___|___|___|

 Donde c es CellID y dist es la distancia de los elementos a encontrar (en el ejemplo, sería 2)
 */
vector <unsigned int> MyastarPlanner::findNeighborCell1 (const unsigned int & CellID, int dist, const unsigned int & cost){

        unsigned int mx, my;
        costmap_->indexToCells(CellID,mx,my);

        //ROS_INFO("Viendo vecinos de index: %u, Map coords: (%u,%u)", CellID, mx,my);

        double  wx, wy;
        vector <unsigned int>  freeNeighborCells;

        for (int x=-dist;x<=dist;x+=dist){
          for (int y=-dist; y<=dist;y+=dist){
            //check whether the index is valid
            //ROS_INFO("A ver: X = %u, Size_X = %u, Y = %u Size_Y = %u",mx+x, (unsigned int)costmap_->getSizeInCellsX(),my+y, (unsigned int)costmap_->getSizeInCellsY());
           if ((mx+x>=0)&&(mx+x < costmap_->getSizeInCellsX())&&(my+y >=0 )&&(my+y < costmap_->getSizeInCellsY())){
               //costmap_->mapToWorld( (unsigned int) mx+x, (unsigned int) my+y, wx, wy);
               //ROS_INFO("Comprobando casilla con Map coords(%u,%u), World coords (%f,%f)", mx+x, my+y ,wx,wy);
               //ROS_INFO("Comprobando casilla con Map coords(%u,%u)", mx+x, my+y);
              if(costmap_->getCost(mx+x,my+y) < cost   && (!(x==0 && y==0))){
                  unsigned int index = costmap_->getIndex(mx+x,my+y);
                 // ROS_INFO("Vecina (%f, %f)", wx,wy);
                  freeNeighborCells.push_back(index);
              }
          }
        }

      }
      return  freeNeighborCells;
}



/*******************************************************************************/
/*  /* Encuentra vecinos x de la casilla c con coste < cost de la siguiente manera:

 ____________________________
|___|___|___|___|___|___|___|
|___|_x_|_x_|_x_|_x_|_x_|___|
|___|_x_|___|___|___|_x_|___|
|___|_x_|___|_c_|___|_x_|___|
|___|_x_|___|___|___|_x_|___|
|___|_x_|_x_|_x_|_x_|_x_|___|
|___|___|___|___|___|___|___|

Donde c es CellID y dist es la distancia de los elementos a encontrar (en el ejemplo, sería 2)
*/
vector <unsigned int> MyastarPlanner::findNeighborCell2 (const unsigned int & CellID, int dist, const unsigned int & cost){

       unsigned int mx, my;
       costmap_->indexToCells(CellID,mx,my);

       //ROS_INFO("Viendo vecinos de index: %u, Map coords: (%u,%u)", CellID, mx,my);

       double  wx, wy;
       vector <unsigned int>  freeNeighborCells;


       for (int x=-dist;x<=dist;++x){

         bool primera_o_ultima = (x == -dist || x == dist);
         int incremento = primera_o_ultima ? 1 : 2*dist;

         for (int y=-dist; y<=dist;y+=incremento){
           //check whether the index is valid
           //ROS_INFO("A ver: X = %u, Size_X = %u, Y = %u Size_Y = %u",mx+x, (unsigned int)costmap_->getSizeInCellsX(),my+y, (unsigned int)costmap_->getSizeInCellsY());
          if ((mx+x>=0)&&(mx+x < costmap_->getSizeInCellsX())&&(my+y >=0 )&&(my+y < costmap_->getSizeInCellsY())){
              //costmap_->mapToWorld( (unsigned int) mx+x, (unsigned int) my+y, wx, wy);
              //ROS_INFO("Comprobando casilla con Map coords(%u,%u), World coords (%f,%f)", mx+x, my+y ,wx,wy);
              //ROS_INFO("Comprobando casilla con Map coords(%u,%u)", mx+x, my+y);
             if(costmap_->getCost(mx+x,my+y) < cost   && (!(x==0 && y==0))){
                 unsigned int index = costmap_->getIndex(mx+x,my+y);
                // ROS_INFO("Vecina (%f, %f)", wx,wy);
                 freeNeighborCells.push_back(index);
             }
         }
       }

     }
     return  freeNeighborCells;
}



/*******************************************************************************/
//Function Name: isContains
//Inputs: the list, the cellID
//Output: true or false
//Description: it is used to check if a cell exists in the open list or in the closed list
/*********************************************************************************/
 bool isContains(set<coupleOfCells,comparator> & set1, int cellID)
 {
   for (set<coupleOfCells,comparator>::iterator it = set1.begin(); it != set1.end(); ++it){
     if (it->index == cellID)
         return true;
  }
   return false;
}

double MyastarPlanner::getMoveCost(unsigned int here, unsigned int there) {
  //calculo el coste de moverme entre celdas adyacentes como la distancia euclídea.
  return calculateHCost(here,there);

}

/*******************************************************************************/
//Function Name: addNeighborCellsToOpenList
//Inputs: the open list, the neighbors Cells and the parent Cell
//Output:
//Description: it is used to add the neighbor Cells to the open list
/*********************************************************************************/
void MyastarPlanner::addNeighborCellsToOpenList(set<coupleOfCells, comparator> & OPL, vector <unsigned int> neighborCells,
  unsigned int parent, float gCostParent, unsigned int goalCell, double dist_start_goal)
{
        coupleOfCells CP;
        unsigned int m_x, m_y;
        double peso;

        for(vector<unsigned int>::iterator it = neighborCells.begin(); it != neighborCells.end(); ++it)
        {
          costmap_->indexToCells(*it, m_x, m_y);
          double distancia_objetivo = calculateHCost(*it, goalCell);

          CP.index = *it; //insert the neighbor cell
          CP.parent= parent; //insert the parent cell
          CP.hCost = distancia_objetivo + footprintCost(m_x, m_y);
          CP.gCost = gCostParent + getMoveCost(parent, *it);
          peso = distancia_objetivo / dist_start_goal;
          CP.fCost = peso*CP.hCost + CP.gCost;

          OPL.insert(CP);
        }
}


  /********VISUALIZAR ESPACIO DE BUSQUEDA *************************/

void MyastarPlanner::inicializaMarkersPoints(visualization_msgs::Marker &marker, string ns, int id, float r, float g, float b) {
        marker.header.frame_id = costmap_ros_->getGlobalFrameID().c_str();
        marker.header.stamp =  ros::Time::now();
        marker.ns = ns;

        marker.action = visualization_msgs::Marker::ADD; //la otra es DELETE
        marker.pose.orientation.w = 0.0;



        marker.id = id;



        marker.type = visualization_msgs::Marker::POINTS;




        // POINTS markers use x and y scale for width/height respectively
        marker.scale.x = costmap_->getResolution();
        marker.scale.y = costmap_->getResolution();


        // Points are green
        marker.color.g = g;
        marker.color.r = r;
        marker.color.b = b;
        marker.color.a = 1.0;

    }

void MyastarPlanner::inicializaMarkersLine_List(visualization_msgs::Marker &marker, string ns, int id, float r, float g, float b) {
        marker.header.frame_id = costmap_ros_->getGlobalFrameID().c_str();
        marker.header.stamp =  ros::Time::now();
        marker.ns = ns;

        marker.action = visualization_msgs::Marker::ADD; //la otra es DELETE
        marker.pose.orientation.w = 0.0;
        marker.pose.position.x = 0.0;
        marker.pose.position.y = 0.0;



        marker.id = id;



        marker.type = visualization_msgs::Marker::SPHERE;




        //Line lists also have some special handling for scale: only scale.x is used and it controls the width of the line segments.
        marker.scale.x = marker.scale.y = 0.5;
       // marker.scale.y = costmap_->getResolution();


        // Points are green
        marker.color.g = g;
        marker.color.r = r;
        marker.color.b = b;
        marker.color.a = 1.0;

    }

void MyastarPlanner::visualizaCoords(ros::Publisher where, visualization_msgs::Marker &marker, double x, double y) {
        //PINTO: cpstart.x, cpstart.y, scale == costmap_->getResolution
        geometry_msgs::Point p;
        p.x = x;
        p.y = y;
        p.z = 0; //¿?

        marker.points.push_back(p); //anyado el punto inicial
        where.publish(marker); //lo publico
        //points.points.pop_back(); //quito el punto de la lista de puntos, lo borro con DELETE cuando lo saque de abiertos.
        }

void MyastarPlanner::visualizaCoordsLineUp(ros::Publisher where, visualization_msgs::Marker &marker, double x, double y, double z) {
        //PINTO: cpstart.x, cpstart.y, scale == costmap_->getResolution

        marker.pose.position.x = x;
        marker.pose.position.y = y;
        where.publish(marker); //lo publico
        //points.points.pop_back(); //quito el punto de la lista de puntos, lo borro con DELETE cuando lo saque de abiertos.
        }

void MyastarPlanner::visualizaCelda(ros::Publisher where, visualization_msgs::Marker &marker, unsigned int index) {
        unsigned int mpose_x, mpose_y;
        double wpose_x, wpose_y;
        costmap_->indexToCells(index, mpose_x, mpose_y);
        costmap_->mapToWorld(mpose_x, mpose_y, wpose_x, wpose_y);
        visualizaCoords(where, marker, wpose_x, wpose_y);

    }

 void MyastarPlanner::visualizaLista(ros::Publisher where, visualization_msgs::Marker &marker, vector<unsigned int> lista) {
     for(vector<unsigned int>::iterator i = lista.begin(); i != lista.end(); ++i)
       {
         unsigned int mpose_x, mpose_y;
         double wpose_x, wpose_y;
         costmap_->indexToCells(*i, mpose_x, mpose_y);
         costmap_->mapToWorld(mpose_x, mpose_y, wpose_x, wpose_y);
         //PINTO: cpstart.x, cpstart.y, scale == costmap_->getResolution
         geometry_msgs::Point p;
         p.x = wpose_x;
         p.y = wpose_y;
         p.z = 0; //¿?

         marker.points.push_back(p);
        }
      where.publish(marker);
 //quitar neighborCells de points .popback
 }
 void MyastarPlanner::limpiaMarkers(ros::Publisher where, visualization_msgs::Marker &marker) {
    if (!marker.points.empty()){
        marker.action = visualization_msgs::Marker::DELETE;
        where.publish(marker);
        marker.action = visualization_msgs::Marker::ADD;
    }
    marker.points.clear();


 }

/* comprueba si la celda1 está contenida en el área cuyo centro es celda2 y cuyo radio es rango */
 bool MyastarPlanner::estaContenida(const unsigned int & celda1, const unsigned int & celda2,
   const int & rango)
   {
     unsigned int c1_x, c1_y;
     costmap_->indexToCells(celda1, c1_x, c1_y);
     std::vector<unsigned int> vecinos;
     std::vector<unsigned int>::iterator it;
     //ROS_INFO("casilla = (%d,%d)", c1_x,c1_y);
     for (int dist = 1; dist <= rango; ++dist){

       vecinos = findNeighborCell2(costmap_->getIndex(c1_x, c1_y), dist, 127);

       for (it = vecinos.begin(); it != vecinos.end(); ++it)
         if (*it == celda2)
          return true;
     }

     return false;
   }



}
