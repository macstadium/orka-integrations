# Advanced settings

Using the advanced settings you can specify mapping between Orka private and public IPs. In case the private network range used by your Orka environment overlaps with a range in your own network, you need to configure the executor to connect to the public address of the Orka node.  
**Note** To get the public IPs of your Orka nodes, contact MacStadium.  

This a template you can use to create the advanced settings file:

```json
{
  "mappings": [
    {
      "private_host": "{node_1_private_ip}", // Private IP of node 1. For example: 10.10.10.4
      "public_host": "{node_1_public_ip}" // Public IP of node 1. Contact MacStadium for its value.
    },
    {
      "private_host": "{node_2_private_ip}",
      "public_host": "{node_2_public_ip}"
    },
    ...
    {
      "private_host": "{node_n_private_ip}",
      "public_host": "{node_n, public_ip}"
    }
  ]
}
```
