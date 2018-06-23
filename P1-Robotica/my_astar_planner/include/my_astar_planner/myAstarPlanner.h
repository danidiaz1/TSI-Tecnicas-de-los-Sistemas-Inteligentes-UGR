/*********************************************************************
*
* Software License Agreement (BSD License)
*
*  Copyright (c) 2008, Willow Garage, Inc.
*  Copyright (c) 2015, Juan Fdez-Olivares
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
* Author: Juan Fdez-Olivares, Eitan Marder-Eppstein
*********************************************************************/
#ifndef MYASTAR_PLANNER_H_
#define MYASTAR_PLANNER_H_

//includes para integrarse en ROS
#include <ros/ros.h>
#include <costmap_2d/costmap_2d_ros.h>
#include <costmap_2d/costmap_2d.h>
#include <nav_core/base_global_planner.h>

#include <geometry_msgs/PoseStamped.h>
#include <nav_msgs/Path.h> //??
#include <angles/angles.h>

#include <tf/tf.h>
#include <tf/transform_datatypes.h>

#include <base_local_planner/world_model.h>
#include <base_local_planner/costmap_model.h>

//para pintar puntos
#include <visualization_msgs/Marker.h>

//includes específicos para hacer referencia a la implementación del algoritmo astar.

#include <vector>
#include <unordered_map>
#include <set>

namespace myastar_planner{
  /**
   * @class myastar_planner
   * @brief Provides an a-star simple global planner that will compute a valid goal point for the local planner by using classical astar implementation.
   */

   using namespace std;
/**
 * @struct coupleOfCells
 * @brief A struct that represents a node, that is, a couple of current and parent cells
 */
struct coupleOfCells {
	unsigned int index;
	unsigned int parent;
	double gCost;
	double hCost;
	double fCost;
};

/**
 * @struct comparator
 * @brief comparator less than for two coupleOfCells
*/
struct comparator{
  bool operator()(const coupleOfCells & left, const coupleOfCells & right) const {
    return (left.fCost < right.fCost);
  }
};



  class MyastarPlanner : public nav_core::BaseGlobalPlanner { //implementa la interfaz que provee nav_core::BaseGlobalPlanner
    public:
      /**
       * @brief  Constructor for the MyastarPlanner
       */
      MyastarPlanner();
      /**
       * @brief  Constructor for the MyastarPlanner
       * @param  name The name of this planner
       * @param  costmap_ros A pointer to the ROS wrapper of the costmap to use for planning
       */
      MyastarPlanner(std::string name, costmap_2d::Costmap2DROS* costmap_ros);

      /**
       * @brief  Initialization function for MyastarPlanner
       * @param  name The name of this planner
       * @param  costmap_ros A pointer to the ROS wrapper of the costmap to use for planning
       */
      void initialize(std::string name, costmap_2d::Costmap2DROS* costmap_ros);

      /**
       * @brief Given a goal pose in the world, compute a plan
       * @param start The start pose
       * @param goal The goal pose
       * @param plan The plan... filled by the planner
       * @return True if a valid plan was found, false otherwise
       */
      bool makePlan(const geometry_msgs::PoseStamped& start,
          const geometry_msgs::PoseStamped& goal, std::vector<geometry_msgs::PoseStamped>& plan);

    private:

      //necesarios para manejar el costmap y el footprint.
      costmap_2d::Costmap2DROS* costmap_ros_;
      double step_size_, min_dist_from_robot_;
      costmap_2d::Costmap2D* costmap_;

      //para publicar el plan
      ros::Publisher plan_pub_;

      //necesarios para manejar las listas de abiertos y cerrados de astar.
      set<coupleOfCells, comparator> openList; //!< the open list: it contains all the expanded cells (current cells)
	    unordered_map<unsigned int, coupleOfCells> closedList; //!< the closed list: contains the explored cells

      // necesario para la seguridad de la ruta
      std::vector<geometry_msgs::Point> footprint_;
      double footprint_radius_max_, footprint_radius_min_;

      // Para mas tarde tener en cuenta solo las casillas fuera del footprint del robot
      int distancia_vecino;
      double cell_size;

      /**
      * @brief comprueba si la celda1 está circumscrita en "rango" casillas en el área
      cuyo centro es celda2
      */
      bool estaContenida(const unsigned int & celda1, const unsigned int & celda2,
        const int & rango);

      /**
       * @brief  Checks the legality of the robot footprint at a position and orientation using the world model
       * @param x_i The x position of the robot
       * @param y_i The y position of the robot
       * @param theta_i The orientation of the robot
       * @return
       */
      double footprintCost(double x_i, double y_i);
      /**
       * @brief  Calcula la estimación del costo de ir desde una casilla (definida por su indice) hasta otra (definida por su índice)
       * @param start El índice de la casilla inicial
       * @param end El índice de la casilla final
       * @return
       */
      double calculateHCost(unsigned int start, unsigned int goal);

      //Función para la comparación de la función heurística aplicada a dos nodos.
      //Devuelve true si f(c1) < f(c2)
      static bool compareFCost(coupleOfCells const &c1, coupleOfCells const &c2);

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
      vector <unsigned int> findNeighborCell1 (const unsigned int & CellID, int dist, const unsigned int & cost);

      /* Encuentra vecino x de la casilla c con coste < cost de la siguiente manera:

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
      vector <unsigned int> findNeighborCell2 (const unsigned int & CellID, int dist, const unsigned int & cost);

      /*******************************************************************************/
      //Function Name: addNeighborCellsToOpenList
      //Inputs: the open list, the neighbors Cells and the parent Cell
      //Output: the open list updated
      //Description: it is used to add the neighbor Cells to the open list
      /*********************************************************************************/
      void addNeighborCellsToOpenList(set<coupleOfCells, comparator> & OPL, vector <unsigned int> neighborCells,
        unsigned int parent, float gCostParent, unsigned int goalCell, double dist_start_goal);

      //devuelve elcosto de moverse desde una casilla "here" hasta otra casilla "there"
      double getMoveCost(unsigned int here, unsigned int there);

      void publishPlan(const std::vector<geometry_msgs::PoseStamped>& path);

      /********VISUALIZAR ESPACIO DE BUSQUEDA *************************/

       //para publicar puntos de abiertos y cerrados
      ros::Publisher marker_Open_publisher;
      ros::Publisher marker_Closed_publisher;
      //para publicar las marcas de los goals
      ros::Publisher marker_Goals_publisher;
      //necesario para guardar la lista de puntos de abiertos y cerrados a visualizar como markers en rviz.
      visualization_msgs::Marker markers_OpenList;
      visualization_msgs::Marker markers_ClosedList;
      //necesario para guardar las line_list que marcan los puntos objetivo recomendados.
      visualization_msgs::Marker markers_Goals;

      void inicializaMarkersPoints(visualization_msgs::Marker &marker, string ns, int id, float r, float g, float b);
      void inicializaMarkersLine_List(visualization_msgs::Marker &marker, string ns, int id, float r, float g, float b);
      void visualizaCoords(ros::Publisher where, visualization_msgs::Marker &marker, double x, double y);
      void visualizaCoordsLineUp(ros::Publisher where, visualization_msgs::Marker &marker, double x, double y, double z);
      void visualizaCelda(ros::Publisher where, visualization_msgs::Marker &marker, unsigned int cell);


      void visualizaLista(ros::Publisher where, visualization_msgs::Marker &marker, vector<unsigned int> lista);
      void limpiaMarkers(ros::Publisher where, visualization_msgs::Marker &marker);

      /************FIN VISUALIZAR ESPACIO DE BUSQUEDA *******************************/



      bool initialized_;
  };
};
#endif
