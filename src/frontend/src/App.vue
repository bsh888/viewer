<template>
  <div id="app">
    <MyViewer msg="MyViewer"/>
  </div>
</template>

<script>
import MyViewer from './components/MyViewer.vue'

export default {
  name: 'App',
  components: {
    MyViewer
  }
}
</script>

<style>
#app {
  text-align: center;
}
</style>
