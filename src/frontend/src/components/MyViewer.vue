<template>
  <div class="MyViewer">
    <!-- <viewer class="images" :images="images" :options="options">
      <img class="image" v-for="(image, index) in images" :src="image.thumbnail" :data-source="image.source" :key="index">
    </viewer> -->
    <viewer :options="options" :images="images"
      @inited="inited"
      class="viewer" ref="viewer"
    >
      <template slot-scope="scope">
        <template v-for="(image, index) in scope.images">
          <img v-if="image.type == 'P'" class="image" :key="index" :src="image.thumbnail" :data-source="image.source" :alt="image.title">
          <img v-if="image.type == 'V'" class="image" :key="index" :src="image.thumbnail" :alt="image.title" @click="playVideo(image)">
        </template>
      </template>
    </viewer>
    <van-popup v-model="showVideo">
      <video :src="videoSrc" controls="controls" loop="loop" autoplay>您的浏览器不支持video标签</video>
    </van-popup>
    <van-notice-bar left-icon="volume-o" :text="pageTexts" />
    <van-pagination v-model="page" :total-items="records" :items-per-page="perPage" :show-page-size="3" force-ellipses @change="changePage" />
    <van-radio-group v-model="mType" class="MType">
      <van-cell-group>
        <van-cell title="图片和视频" clickable @click="changeType(mType = '')">
          <template #right-icon>
            <van-radio name="" />
          </template>
        </van-cell>
        <van-cell title="显示图片" clickable @click="changeType(mType = 'P')">
          <template #right-icon>
            <van-radio name="P" />
          </template>
        </van-cell>
        <van-cell title="显示视频" clickable @click="changeType(mType = 'V')">
          <template #right-icon>
            <van-radio name="V" />
          </template>
        </van-cell>
      </van-cell-group>
    </van-radio-group>
    <van-field v-model="sPage" center clearable label="跳转的页数" type="digit" :placeholder="setPagePlaceholder">
      <template #button>
        <van-button size="small" type="primary" @click="setPage">跳转</van-button>
      </template>
    </van-field>
    <van-field v-model="sPerPage" center clearable label="每页记录数" type="digit" :placeholder="setPerPagePlaceholder">
      <template #button>
        <van-button size="small" type="primary" @click="setPerPage">设置</van-button>
      </template>
    </van-field>
    <van-field readonly clickable :value="startDateTime" label="开始日期" placeholder="点击选择日期" @click="showMinDateTime = true" />
    <van-popup v-model="showMinDateTime" round position="bottom">
      <van-datetime-picker v-model="minDateTime" type="datetime" title="选择年月日" :min-date="minDate" :max-date="maxDate" @confirm="setMinDateTime" @cancel="showMinDateTime = false" />
    </van-popup>
    <van-field readonly clickable :value="endDateTime" label="结束日期" placeholder="点击选择日期" @click="showMaxDateTime = true" />
    <van-popup v-model="showMaxDateTime" round position="bottom">
      <van-datetime-picker v-model="maxDateTime" type="datetime" title="选择年月日" :min-date="minDate" :max-date="maxDate" @confirm="setMaxDateTime" @cancel="showMaxDateTime = false" />
    </van-popup>
  </div>
</template>

<script>
import axios from 'axios'

import 'viewerjs/dist/viewer.css'
import Viewer from 'v-viewer'
import Vue from 'vue'
Vue.use(Viewer)

import 'vant/lib/index.css'
import { NoticeBar, Pagination, Field, Button, Popup, DatetimePicker, RadioGroup, Radio, CellGroup, Cell } from 'vant'
Vue.use(NoticeBar)
Vue.use(Pagination)
Vue.use(Field)
Vue.use(Button)
Vue.use(Popup)
Vue.use(DatetimePicker)
Vue.use(RadioGroup)
Vue.use(Radio)
Vue.use(CellGroup)
Vue.use(Cell)

import moment from 'moment'

const PER_PAGE = window.CONFIG && window.CONFIG.perPage || 20

let ls = window.localStorage

let lsPage = ls.getItem('viewer:MyViewer:page')
lsPage = (lsPage ? JSON.parse(lsPage) : 1);

let lsPerPage = ls.getItem('viewer:MyViewer:perpage')
lsPerPage = (lsPerPage ? JSON.parse(lsPerPage) : PER_PAGE);

// create an axios instance
const service = axios.create({
  baseURL: window.CONFIG && window.CONFIG.apiHost || 'http://127.0.0.1:8081/',
  withCredentials: true, // 跨域请求时发送 cookies
  timeout: 10000 // request timeout
})

// request interceptor
service.interceptors.request.use(
  config => {
    config.headers['jweToken'] = 'ABCD'
    return config
  },
  error => {
    // Do something with request error
    // console.log(888, error) // for debug
    Promise.reject(error)
  }
)

// response interceptor
service.interceptors.response.use(
  response => {
    return response.data
  },
  error => {
    console.log('err: ' + error) // for debug
    if (axios.isCancel(error)) {
      throw new Error('request has been cancelled')
    }
    return Promise.reject(error)
  }
)

export default {
  name: 'MyViewer',
  props: {
    msg: String
  },
  components: {
  },
  data() {
    return {
      page: 1,
      sPage: '',
      setPagePlaceholder:'',
      sPerPage: '',
      setPerPagePlaceholder:'',
      pages: 1,
      pageTexts: '',
      records: 0,
      perPage: PER_PAGE,
      mType: '',
      apiHost: '',
      dealPics: '',
      dealVideos: '',
      sourcePics: '',
      sourceVideos: '',
      showVideo: false,
      videoSrc: '',
      minDate: new Date(2000, 0, 1),
      maxDate: new Date(),
      showMinDateTime: false,
      startDateTime: '',
      minDateTime: new Date(2000, 0, 1),
      showMaxDateTime: false,
      endDateTime: '',
      maxDateTime: new Date(2000, 0, 1),
      options: {
        url: 'data-source'
      },
      images: [
        // {thumbnail: 'https://picsum.photos/id/26/300/200', source: 'https://picsum.photos/id/26/600/400'},
        // {thumbnail: 'https://picsum.photos/id/27/300/200', source: 'https://picsum.photos/id/27/600/400'},
        // {thumbnail: 'https://picsum.photos/id/28/300/200', source: 'https://picsum.photos/id/28/600/400'},
        // {thumbnail: 'https://picsum.photos/id/29/300/200', source: 'https://picsum.photos/id/29/600/400'},
        // {thumbnail: 'https://picsum.photos/id/30/300/200', source: 'https://picsum.photos/id/10/600/400'},
      ]
    }
  },
  methods: {
    inited (viewer) {
      this.$viewer = viewer
    },

    playVideo(image) {
      this.showVideo = true
      this.videoSrc = image.source
    },

    changePage(page) {
      ls.setItem('viewer:MyViewer:page', JSON.stringify(page))
      this.getFileList(page)
    },

    setPage() {
      if (!this.sPage) {
        this.getFileList()
        return
      }
      this.sPage = parseInt(this.sPage)
      if (this.sPage > 0 && this.sPage <= this.pages) {
        this.getFileList(this.sPage)
      }
    },

    setPerPage() {
      if (!this.sPerPage) {
        this.perPage = lsPerPage
        this.getFileList(this.page, this.perPage)
        return
      }
      this.sPerPage = parseInt(this.sPerPage)
      if (this.sPerPage > 0) {
        this.perPage = this.sPerPage
        ls.setItem('viewer:MyViewer:perpage', JSON.stringify(this.perPage))
        this.getFileList(this.page, this.perPage)
      }
    },

    changeType() {
      this.getFileList()
    },

    setMinDateTime() {
      this.startDateTime = moment(this.minDateTime).format('YYYY-MM-DD HH:mm:ss')
      this.showMinDateTime = false
      this.getFileList()
    },

    setMaxDateTime() {
      this.endDateTime = moment(this.maxDateTime).format('YYYY-MM-DD HH:mm:ss')
      this.showMaxDateTime = false
      this.getFileList()
    },

    // 获取文件列表
    getFileList(page, perPage) {
      this.page = page || lsPage
      this.perPage = perPage || lsPerPage

      let query = {
        'type': this.mType,
        'min-date-time': this.startDateTime,
        'max-date-time': this.endDateTime,
        'per-page': this.perPage,
        'page': this.page
      }
      service({
        url: this.apiHost + 'api/filelist',
        method: 'get',
        params: query
      }).then(response => {
        if (response.code === 10000 && response.data.count >= 0) {
          this.records = response.data.count
          this.pageTexts = '总共【' + this.records + '】条记录，每页展示【' + this.perPage + '】条'
          this.pages = Math.ceil(this.records / this.perPage)
          this.setPagePlaceholder = '请输入1-' + this.pages + '的数字'
          this.setPerPagePlaceholder = '请输入1-' + this.records + '的数字'
          this.images = []
          if (response.data.count == 0) {
            return
          }
          if (!response.data.list) {
            ls.removeItem('viewer:MyViewer:page')
            ls.removeItem('viewer:MyViewer:perpage')
            this.getFileList(1, PER_PAGE)
            return
          }
          for (let i = 0; i < response.data.list.length; i++) {
            let mType = '', thumbnail = '', source = ''
            mType = response.data.list[i].type
            if (mType == 'P') {
              thumbnail = this.dealPics + response.data.list[i].path
              source = this.sourcePics + response.data.list[i].path
            } else if (mType == 'V') {
              thumbnail = this.dealVideos + response.data.list[i].path
              source = this.sourceVideos + response.data.list[i].path.replace('.jpg', '.mp4')
            }
            
            this.images.push({
              type: mType,
              title: response.data.list[i].datetime,
              thumbnail: thumbnail,
              source: source
            })
          }
        }
      })
    }
  },
  mounted() {
    service({
      url: '/api/config',
      method: 'get',
    }).then(response => {
      if (response.code === 10000) {
        this.apiHost = response.data.host
        this.dealPics = response.data.dealpics
        this.dealVideos = response.data.dealvideos
        this.sourcePics = response.data.sourcepics
        this.sourceVideos = response.data.sourcevideos

        this.getFileList(lsPage, lsPerPage)
        setTimeout(() => {
          this.page = lsPage
          this.perPage = lsPerPage
        }, 300)
      }
    })
  }
}
</script>

<style>
.image {
  height: 200px;
  cursor: pointer;
  margin: 5px;
  display: inline-block;
}
.MType {
  text-align: left;
}
</style>
