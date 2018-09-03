
## Introducción

Este documento tiene como finalidad describir los pasos necesarios para el despliegue de Openstack utilizando kolla y kolla-ansible en un entorno virtual (vmware, virtualbox, kvm, etc.)

Una particularidad de kolla es que los componentes de OpenStack están distribuidos en uno o más contenedores Docker.

### Configuración de las máquinas virtuales


#### Interfaces de red

Deberemos configurar 3 interfaces por cada nodo:


eth0 ⇒ NAT (para conectarse a Internet)

eth1 ⇒ Internal (la que utilizan los nodos para comunicarse entre si)

eth2 ⇒ Bridge - sin ip  (Para la conexión de las instancias/Netutron/Nova) Habilitar modo promiscuo.


#### Memoria, disco y cpu

Estos valores dependerán de la capacidad de nuestro host.

### Setup del deployer y de los nodos (Con Ansible)

Setup del deployer y de los nodos con Ansible

El repositorio https://github.com/gsanso/kolla-ansible-wdcs contiene algunos playbooks que realizarán algunas configuraciones en los nodos, tanto en el deployer (operator) como en los nodos que formaran parte de la nube Openstack. Por ello este playbook se ejecuta desde cualquier ordenador que tenga disponible acceso por ssh a los nodos.

    git clone http://git.walhalladcs.com/kolla-ansible-wdcs/

Antes de ejecutar los playbooks debemos editar los siguientes ficheros:

`group_vars/all.yml`

Aquí definimos algunas variables importantes

`servers.yml` (Solo si utilizamos Vagrant)

`inventory`
Aquí debemos modificar los valores de:

- ansible_host
- ansible_user
- ansible_ssh_pass

`files/multinode`

Este es el fichero inventory que utilizará kolla para el despliegue

`files/globals.yml`

Este es el fichero con la configuración principal de kolla donde especificaremos la versión de Openstack a instalar así como sus módulos y las diferentes formas de configuración disponibles.

Ejemplo (Esta configuración básica me funcionó):

    kolla_base_distro: "ubuntu"
    openstack_release: "queens"
    kolla_internal_vip_address: "172.16.117.20"
    kolla_external_vip_address: "172.16.3.20"
    network_interface: "eth1"
    neutron_external_interface: "eth2"
    enable_ceph: "yes"
    enable_ceph_rgw: "yes"
    enable_cinder: "yes"
    enable_heat: "no"
    glance_backend_file: "no"
    glance_backend_ceph: "yes"
    nova_compute_virt_type: "qemu"
    enable_neutron_provider_networks: "yes"
    ceph_osd_store_type: "filestore"


###### Ejecutamos el playbook para configurar deployer y nodos:


        ansible-playbook -i inventory site.yml

<span style="color:red"> NOTA: Si dá error ejecutar nuevamente</span> (fixme)

Ejecutando ansible-playbook contra el fichero `site.yml` se ejecutarán los siguientes playbooks:


- deploy_authorized_keys.yml    (Despliega nuestra clave pública en los nodos)     

- setup-deployer.yml (Configura el nodo deployer)

- setup-nodes.yml (Configura los nodos que utilizaremos para el despliegue)


### Setup del deployer y de los nodos de forma manual

Instalar ansible en nuestro equipo

Agregamos el siguiente repositorio para poder instalar una versión actualizada de Ansible (Las pruebas fueron relaizadas con la versión ansible 2.6.3)

    sudo apt-add-repository ppa:ansible/ansible

    sudo apt-get install ansible

Instalamos el sshpass para que Ansible pueda autenticar por ssh mediante contraseña de forma automática.

    sudo apt-get install sshpass


También necesitamos modificar la configuración de Ansible

Editar fichero `/etc/ansible/ansible.cfg`:

    [defaults]
    host_key_checking=False
    pipelining=True
    forks=100
    deprecation_warnings=False  
 Esto deshabilita los warnings que avisan de sintaxis que va a ser deprecada en las proximas vers de Ansible


Instalar pip:

    sudo apt install python-pip
    sudo apt-get install python2.7-dev

Tambien instalamos los clientes openstack que necesitaremos luego para verificar la instalación:

    sudo pip install python-openstackclient python-glanceclient python-neutronclient

### Instalar kolla y kolla-ansible

Hay dos formas de instalar kolla y kolla-ansible:

**Método 1**: Instalar con **pip**

Instalar kolla y kolla-ansible con pip

    sudo pip install kolla
    sudo pip install kolla-ansible

**Método 2**: Clonar los repositorios con **git** y luego instalar las dependencias
Clonamos el branch de la versiòn de Openstack que vamos a utilizar

    git clone -b stable/queens --single-branch https://github.com/openstack/kolla
    git clone -b stable/queens --single-branch  https://github.com/gsanso/kolla-ansible

Instalamos las dependencias:

    pip install -r kolla/requirements.txt
    pip install -r kolla-ansible/requirements.txt


Copiar fichero de configuración de kolla-ansible y el fichero con las contraseñas de los servicios

Copiamos `globals.yml` y `passwords.yml` al directorio `/etc/kolla`

      cp -r /usr/local/share/kolla-ansible/etc_examples/kolla/ /etc/

Nota: El fichero `globals.yml` debe ser editado de acuerdo a nuestras necesidades y el passwords.yml no contiene contraseñas ya que luego o bien las agregaremos manualmente o más adelante utilizaremos un generador aleatorio de contraseñas.

Creamos directorio para los ficheros de configuración de kolla

        mkdir -p /etc/kolla/config

Este directorio es importante crearlo ya que aquí pondremos los ficheros de configuración de los componentes de Openstack que deseamos modificar. Por ejemplo si necesitamos realizar un cambio en Nova crearíamos un fichero /etc/kolla/config/nova.conf

Directorio con los ficheros de Ansible

En caso de instalar kolla desde el repositorio git de ahora en mas nuestro directorio de trabajo será `$HOME/kolla-ansible/ansible`

    cd kolla-ansible/ansible

Copiar el fichero `multinode` (el fichero inventory de Ansible) a nuestro directorio actual).

El fichero multinode es lo que en Ansible se conoce como el fichero inventory solo que con otro nombre para identificar que nuestra instalación es multinodo.
En caso de no disponer previamente de este fichero podemos editar el que viene de ejemplo:

    cd kolla-ansible/ansible
    cp /usr/local/share/kolla-ansible/ansible/inventory/multinode .


Copiar las keys de nuestro host al nodo deployer y al resto de los nodos

    ssh-copy-id walhalla@kolla-deployer
    ssh-copy-id walhalla@kolla-ct1
       ...

Test accesso a los nodos

    ansible -i multinode all -m ping

    ansible -i inventory all -m ping


#### Passwords de los servicios

Las passwords que utilizaremos en nuestro despliegue son almacenadas en `/etc/kolla/passwords.yml`. Por defecto todas las passwords están en blanco por ello necesitamos ejecutar el generador de random passwords el cual agregará las passwords creadas al fichero `/etc/kolla/passwords.yml`

Si instalamos mediante git:

    sudo ../tools/generate_passwords.py

Si instalamos mediante pip

    sudo /usr/local/bin/kolla-genpwd


## Instalación

0) Nos conectamos vía ssh al nodo deployer (kolla-deployer) y verificamos que tenemos conexión por ssh a los nodos.

    ssh usuario@kolla-deployer
    ansible -i multinode all -m ping

Si falla deberemos copiar la clave pública del kolla-deployer a los nodos:

    ssh-copy-id usuario@kolla-ct1
    ssh-copy-id usuario@kolla-ct2
    ssh-copy-id usuario@kolla-ct3
    ...

1) Bootstrap de las dependencias para el despliegue de los servers con kolla (dependencias como por ej Docker):

    kolla-ansible -i ./multinode bootstrap-servers

2) Realizamos un chequeo antes del despliegue de los hosts:

    kolla-ansible -i ./multinode prechecks

3) Descargamos las imagenes docker???????????'

    kolla-ansible -i ./multinode pull

4) Finalmente procedemos al despliegue de OpenStack y guardamos un log con el output:

    kolla-ansible -i ./multinode deploy  2>&1 | tee "deploy-$(date +%Y-%m-%d_%H%M%S).log"


## Post Instalación (init-runonce)

(Nota: En un futuro los siguientes pasos se realizaran mediante Ansible)

Para generar el fichero openrc:

        sudo kolla-ansible post-deploy

        source /etc/kolla/admin-openrc.sh

Ejecutar el script tools/init-runonce. El script crea una red publica y una red demo. Además descarga una imagen de cirros y
crea varios sabores diferentes.

        vim ../tools/init-runonce

o

        vim /usr/local/share/kolla-ansible/init-runonce


Modificar la sección de la public network con la subred que tenemos asignada.

Ej:

      EXT_NET_CIDR='200.126.7.0/24'
      EXT_NET_RANGE='start=200.126.7.150,end=200.126.7.199'
      EXT_NET_GATEWAY='200.126.7.254'


Ejecutar init-runonce

      init-runonce


6) Verificar funcionamiento básico

      source /etc/kolla/admin-openrc.sh

      openstack user list


Listamos las imagenes disponibles




Elegimos una imagen

    export IMAGE_NAME=1234-aaaa-4567-bbbb-12345678

Creamos una instancia a partir de la imagen y el sabor elegido

    openstack server create --image ${IMAGE_NAME} --flavor m1.tiny --key-name mykey  --network demo-net  demo1


### Desinstalación

Para detener todos los contenedores (y eliminar las imagenes????):

        kolla-ansible -i  ./multinode destroy --yes-i-really-really-mean-it

En mi experiencia este método no ha sido fiable.


### Logs

Los logs de los servicios de los contenedores pueden accederse desde cada host en el dir

`/var/lib/docker/volumes/kolla_logs/_data/SERVICE_NAME`


También es posible accederlos desde dentro del contenedor en `/var/log/kolla/SERVICE_NAME`


##### Logs de Openstack

Editar `/etc/kolla/globals.yml` y modificar lo siguiente:

    enable_central_logging: "yes"
    openstack_logging_debug: "yes"

Luego para acceder a los logs accedemos a Kibana vía web:


    http:/<kolla_external_vip_address>:5601


#### Ansible comandos adhoc

    ansible -i multinode kolla-ct1 -b -a "ps aux"

    ansible -i multinode kolla-ct1  -a "docker ps"

    ansible -i multinode all -a "docker ps"


### TLS

vim /etc/kolla/globals.yml

    kolla_enable_tls_external: "yes"

Crear directorio para certificados

    sudo mkdir -p /etc/kolla/certificates/private

Generamos los certificados en base a la configuración del globals.yml:

    ../tools/kolla-ansible -i ./multinode certificates


### Mariadb

    ../tools/kolla-ansible -i ./multinode reconfigure --tags mariadb


### Cinder con LVM



    sudo pvcreate  /dev/vdb
    sudo vgcreate cinder-volumes /dev/vdb


También podemos utilizar una imágen para emular un disco real.

    #!/bin/bash

    mount -t xfs /dev/vdb1 /mnt
    free_device=$(losetup -f)
    fallocate -l 20G /mnt/cinder_data.img
    losetup $free_device /mnt/cinder_data.img
    pvcreate $free_device
    vgcreate cinder-volumes $free_device



https://bugs.launchpad.net/kolla/+bug/1631072

### CEPH

Para utilizar CEPH debemos tener los siguientes parámetros en el fichero /etc/kolla/globals.yml


    enable_ceph: "yes"
    enable_ceph_rgw: "yes"
    enable_cinder: "yes"
    glance_backend_file: "no"
    glance_backend_ceph: "yes"


Para que Kolla sepa que discos están disponibles para CEPH es necesario crear un label con el nombre *KOLLA_CEPH_OSD_BOOTSTRAP*

Por ejemplo:

    export DISK="/dev/vdb"
    parted $DISK -s -- mklabel gpt mkpart KOLLA_CEPH_OSD_BOOTSTRAP 1 -1




vim `/etc/kolla/config/ceph.conf`:

    [global]
    mon max pg per osd = 10000        # >= luminous


Modificar la configuración de un componente de Openstack

Debemos crear el directorio /etc/kolla/config  

    mkdir -p /etc/kolla/config

Y dentro de ese directorio colocar el fichero con la configuración deseada. Por ejemplo para modificar Nova para que utilice qemu haríamos lo siguiente:

vim `/etc/kolla/config/nova.conf`:

    [libvirt]
    virt_type=qemu
    cpu_mode = none
