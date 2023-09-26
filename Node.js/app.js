import React, { useEffect, useState } from 'react';
import { View, Text } from 'react-native';
import axios from 'axios'; // ถ้าใช้ axios

export default function App() {
  const [data, setData] = useState([]);

  useEffect(() => {

    axios.get('http://your-server-url/data')
      .then((response) => setData(response.data))
      .catch((error) => console.error('Error fetching data: ', error));
  }, []);

  return (
    <View>
      {data.map((item) => (
        <View key={item.id}>
          <Text>{item.name}</Text>
          <Text>{item.status}</Text>
        </View>
      ))}
    </View>
  );
}
