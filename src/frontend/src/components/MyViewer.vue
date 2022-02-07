<template>
  <div class="MyViewer">
    <!-- <viewer class="images" :images="images" :options="options">
      <img class="image" v-for="(image, index) in images" :src="image.thumbnail" :data-source="image.source" :key="index">
    </viewer> -->
    <van-checkbox-group v-model="imageSelected" ref="imageSelected">
      <viewer :options="options" :images="images"
        @inited="inited"
        class="viewer" ref="viewer"
      >
        <template slot-scope="scope">
          <template v-for="(image, index) in scope.images">
            <div class="file" :key="index">
              <van-icon v-if="image.isliked" name="like" class="like" color="orangered" size="25px" @click="likeFile(image)" />
              <van-icon v-else name="like" class="like" color="white" size="25px" @click="likeFile(image)" />
              <van-icon name="close" class="close" color="lightyellow" size="25px" @click="delFile(image)" />
              <van-checkbox v-if="deletev===1" icon-size="22px" :name="image" class="select-image"></van-checkbox>
              <img class="image" v-if="image.type == 'P'" :key="index" :src="image.thumbnail" :data-source="image.source" :alt="image.title">
              <img class="image" v-if="image.type == 'V'" :key="index" :src="image.thumbnail" :alt="image.title" @click="playVideo(image)">
            </div>
          </template>
        </template>
      </viewer>
    </van-checkbox-group>
    <van-popup v-model="showVideo">
      <video :src="videoSrc" controls="controls" loop="loop" autoplay>您的浏览器不支持video标签</video>
    </van-popup>
    <van-notice-bar left-icon="volume-o" :text="pageTexts" />
    <van-pagination v-model="page" :total-items="records" :items-per-page="perPage" :show-page-size="3" force-ellipses @change="changePage" />
    <van-field v-if="deletev===1" name="checkboxGroup" center label="操作">
      <template #input>
        <van-button class="option" size="small" type="primary" @click="checkAll">全选</van-button>
        <van-button class="option" size="small" type="info" @click="toggleAll">反选</van-button>
        <van-button class="option" size="small" type="danger" @click="deleteSelected">删除</van-button>
      </template>
    </van-field>
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
    <van-checkbox-group v-model="checkboxArr" class="MType">
      <van-cell-group>
        <van-cell title="显示喜欢" clickable @click="showLike">
          <template #right-icon>
            <van-checkbox name="like" ref="checkboxLike" />
          </template>
        </van-cell>
        <van-cell title="显示已删除" clickable @click="showDelete">
          <template #right-icon>
            <van-checkbox name="delete" ref="checkboxDelete" />
          </template>
        </van-cell>
      </van-cell-group>
    </van-checkbox-group>
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
    <van-field name="checkboxGroup" center label="初始化">
      <template #input>
        <van-button class="option" size="small" type="danger" @click="initSystem">启动</van-button>   
      </template>
    </van-field>
    <van-progress :percentage="50" />
  </div>
</template>

<script>
import axios from 'axios'

import 'viewerjs/dist/viewer.css'
import Viewer from 'v-viewer'
import Vue from 'vue'
Vue.use(Viewer)

import 'vant/lib/index.css'
import { Icon, NoticeBar, Pagination, Field, Button, Popup, DatetimePicker, RadioGroup, Radio, CellGroup, Cell, Checkbox, CheckboxGroup, Dialog, Notify, Progress } from 'vant'
Vue.use(Icon)
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
Vue.use(Checkbox)
Vue.use(CheckboxGroup)
Vue.use(Dialog)
Vue.use(Notify)
Vue.use(Progress)

import moment from 'moment'

const PER_PAGE = window.CONFIG && window.CONFIG.perPage || 20

let ls = window.localStorage

let lsMType = ls.getItem('viewer:MyViewer:mType')
lsMType = (lsMType ? JSON.parse(lsMType) : '')

let lsLike = ls.getItem('viewer:MyViewer:like')
lsLike = (lsLike ? JSON.parse(lsLike) : -1)

let lsDelete = ls.getItem('viewer:MyViewer:delete')
lsDelete = (lsDelete ? JSON.parse(lsDelete) : 0)

let lsPage = ls.getItem('viewer:MyViewer:page')
lsPage = (lsPage ? JSON.parse(lsPage) : 1)

let lsPerPage = ls.getItem('viewer:MyViewer:perpage')
lsPerPage = (lsPerPage ? JSON.parse(lsPerPage) : PER_PAGE)

let lsStartDateTime = ls.getItem('viewer:MyViewer:startDateTime')
lsStartDateTime = (lsStartDateTime ? JSON.parse(lsStartDateTime) : '')

let lsEndDateTime = ls.getItem('viewer:MyViewer:endDateTime')
lsEndDateTime = (lsEndDateTime ? JSON.parse(lsEndDateTime) : '')

// create an axios instance
const service = axios.create({
  baseURL: window.CONFIG && window.CONFIG.apiHost || 'http://192.168.3.111:8081/',
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
      like: -1,
      deletev: 0,
      checkboxArr: [],
      imageSelected: [],
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
      this.page = page
      ls.setItem('viewer:MyViewer:page', JSON.stringify(page))
      this.getFileList()
    },

    setPage() {
      if (!this.sPage) {
        this.initSet()
        this.getFileList()
        return
      }
      this.sPage = parseInt(this.sPage)
      if (this.sPage > 0 && this.sPage <= this.pages) {
        this.changePage(this.sPage)
      }
    },

    setPerPage() {
      if (!this.sPerPage) {
        this.initSet()
        this.getFileList()
        return
      }
      this.sPerPage = parseInt(this.sPerPage)
      if (this.sPerPage > 0) {
        this.initSet()
        this.perPage = this.sPerPage
        ls.setItem('viewer:MyViewer:perpage', JSON.stringify(this.perPage))
        this.getFileList()
      }
    },

    initSystem() {
      
    },

    initSet() {
      this.mType = ''
      this.like = -1
      this.deletev = 0
      this.checkboxArr = []
      this.page = 1
      this.perPage = PER_PAGE
      this.startDateTime = ''
      this.endDateTime = ''

      ls.removeItem('viewer:MyViewer:mType')
      ls.removeItem('viewer:MyViewer:like')
      ls.removeItem('viewer:MyViewer:page')
      ls.removeItem('viewer:MyViewer:perpage')
      ls.removeItem('viewer:MyViewer:startDateTime')
      ls.removeItem('viewer:MyViewer:endDateTime')
    },

    changeType() {
      ls.setItem('viewer:MyViewer:mType', JSON.stringify(this.mType))
      this.getFileList()
    },

    showLike() {
      this.$refs.checkboxLike.toggle()
      if (this.checkboxArr.includes('like')) {
        this.like = 0
      } else {
        this.like = 1
      }
      ls.setItem('viewer:MyViewer:like', JSON.stringify(this.like))
      this.getFileList()
    },

    showDelete() {
      this.$refs.checkboxDelete.toggle()
      if (this.checkboxArr.includes('delete')) {
        this.deletev = 0
      } else {
        this.deletev = 1
      }
      ls.setItem('viewer:MyViewer:delete', JSON.stringify(this.deletev))
      this.getFileList()
    },

    checkAll() {
      this.$refs.imageSelected.toggleAll(true);
    },

    toggleAll() {
      this.$refs.imageSelected.toggleAll();
    },

    deleteSelected() {
      Dialog.confirm({
        title: '确认删除',
        message: '确定要删除选中文件吗？此操作会删除磁盘文件，不可恢复！！！',
      }).then(() => {
        for (let i = 0; i < this.imageSelected.length; i++) {
          (function(i, _this) {
            setTimeout(() => {
              service({
                url: '/api/real-delete/' + _this.imageSelected[i].id,
                method: 'delete'
              }).then(response => {
                if (response.code === 10000) {
                  Notify({ type: 'danger', duration: 500, message: _this.imageSelected[i].path + '删除成功' })
                  _this.getFileList()
                }
              })
            }, 500 * i)
          }(i, this))
        }
      }).catch(() => {
        // on cancel
      })
    },

    setMinDateTime() {
      this.startDateTime = moment(this.minDateTime).format('YYYY-MM-DD HH:mm:ss')
      ls.setItem('viewer:MyViewer:startDateTime', JSON.stringify(this.startDateTime))
      this.showMinDateTime = false
      this.getFileList()
    },

    setMaxDateTime() {
      this.endDateTime = moment(this.maxDateTime).format('YYYY-MM-DD HH:mm:ss')
      ls.setItem('viewer:MyViewer:endDateTime', JSON.stringify(this.endDateTime))
      this.showMaxDateTime = false
      this.getFileList()
    },

    // 获取文件列表
    getFileList(mType, page, perPage, startDateTime, endDateTime, like, deletev) {
      mType = mType || this.mType
      page = page || this.page
      perPage = perPage || this.perPage
      startDateTime = startDateTime || this.startDateTime
      endDateTime = endDateTime || this.endDateTime
      like = like || this.like
      deletev = deletev || this.deletev

      let query = {
        'type': mType,
        'min-date-time': startDateTime,
        'max-date-time': endDateTime,
        'per-page': perPage,
        'page': page,
        'like': like,
        'delete': deletev
      }
      service({
        url: this.apiHost + 'api/filelist',
        method: 'get',
        params: query
      }).then(response => {
        if (response.code === 10000 && response.data.count >= 0) {
          this.records = response.data.count
          this.pageTexts = '总共【' + this.records + '】条记录，每页展示【' + perPage + '】条'
          this.pages = Math.ceil(this.records / perPage)
          this.setPagePlaceholder = '请输入1-' + this.pages + '的数字'
          this.setPerPagePlaceholder = '请输入1-' + this.records + '的数字'
          this.images = []
          if (response.data.count == 0) {
            return
          }
          if (!response.data.list) {
            this.initSet()
            this.getFileList()
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
              id: response.data.list[i].id,
              type: mType,
              isliked: response.data.list[i].isliked,
              isdeleted: response.data.list[i].isdeleted,
              title: response.data.list[i].datetime,
              thumbnail: thumbnail,
              source: source,
              path: response.data.list[i].path
            })
          }
        }
      })
    },

    likeFile(image) {
      service({
        url: '/api/like/' + image.id,
        method: 'put',
        params: {isliked: image.isliked}
      }).then(response => {
        if (response.code === 10000) {
          if (image.isliked == 1) {
            Notify({ type: 'warning', duration: 1000, message: image.path + '已取消喜欢' })
          } else {
            Notify({ type: 'success', duration: 1000, message: image.path + '已喜欢' })
          }
          this.getFileList()
        }
      })
    },

    delFile(image) {
      let tips = image.isdeleted === 1 ? '取消' : '标记'
      Dialog.confirm({
        title: tips + '删除',
        message: '确定要' + tips + '删除吗？',
      }).then(() => {
        service({
          url: '/api/delete/' + image.id,
          method: 'put',
          params: {isdeleted: image.isdeleted}
        }).then(response => {
          if (response.code === 10000) {
            if (image.isdeleted == 1) {
              Notify({ type: 'success', duration: 1000, message: image.path + '已取消标记删除' })
            } else {
              Notify({ type: 'warning', duration: 1000, message: image.path + '已标记删除' })
            }
            this.getFileList()
          }
        })
      }).catch(() => {
        // on cancel
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

        this.getFileList(lsMType, lsPage, lsPerPage, lsStartDateTime, lsEndDateTime, lsLike, lsDelete)
        setTimeout(() => {
          this.mType = lsMType
          this.like = lsLike
          this.deletev = lsDelete
          this.page = lsPage
          this.perPage = lsPerPage
          this.startDateTime = lsStartDateTime
          this.endDateTime = lsEndDateTime
        }, 300)
      }
    })
  }
}
</script>

<style>
.file {
  position: relative;
  display: inline-block;
}
.like {
  position: absolute;
  left: 8px;
  bottom: 8px;
}
.close {
  position: absolute;
  right: 8px;
  top: 8px;
}
.select-image {
  position: absolute;
  left: 8px;
  top: 8px;
}
.image {
  width: 160px;
  height: 160px;
  cursor: pointer;
  margin: 4px;
  display: inline-block;
  border-radius: 20px;
}
.MType {
  text-align: left;
}
.option {
  margin-left: 10px;
}
</style>
